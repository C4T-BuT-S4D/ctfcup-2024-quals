package fs

import (
	"io"
)

type MultiReadSeeker struct {
	files          []SizedReadSeeker
	pos            int64
	posInFile      int64
	prefixSizes    []int64
	currentFileIdx int
	totalSize      int64
}

type SizedReadSeeker interface {
	io.ReadSeeker
	Size() int64
}

func NewMultiReadSeeker(files []SizedReadSeeker) *MultiReadSeeker {
	totalSize := int64(0)
	prefixSizes := make([]int64, len(files)+1)
	for i, f := range files {
		totalSize += f.Size()
		prefixSizes[i+1] = totalSize
	}

	return &MultiReadSeeker{
		files:          files,
		pos:            0,
		posInFile:      0,
		currentFileIdx: 0,
		totalSize:      totalSize,
		prefixSizes:    prefixSizes,
	}
}

func (m *MultiReadSeeker) Size() int64 {
	return m.totalSize
}

func (m *MultiReadSeeker) Read(p []byte) (int, error) {
	nRead := 0
	currentFileRead := 0
	for nRead != len(p) && m.currentFileIdx < len(m.files) {
		m.files[m.currentFileIdx].Seek(m.posInFile, io.SeekStart)
		var err error
		currentFileRead, err = m.files[m.currentFileIdx].Read(p[nRead:])
		if err != nil {
			if err == io.EOF {
				m.posInFile = 0
				m.currentFileIdx++
				continue
			}
			return 0, err
		}

		nRead += currentFileRead
		m.pos += int64(currentFileRead)

		if m.posInFile+int64(currentFileRead) < m.files[m.currentFileIdx].Size() {
			break
		}
		m.posInFile = 0
		m.currentFileIdx++
	}

	m.posInFile += int64(currentFileRead)

	if nRead == 0 {
		return 0, io.EOF
	}
	return nRead, nil
}

func (m *MultiReadSeeker) Seek(offset int64, whence int) (int64, error) {
	pos := m.pos
	if whence == io.SeekStart {
		pos = offset
	} else if whence == io.SeekEnd {
		pos = m.totalSize + offset
	} else if whence == io.SeekCurrent {
		pos += offset
	} else {
		return 0, io.EOF
	}
	if 0 > pos || pos >= m.totalSize {
		return 0, io.EOF
	}

	lb := 0
	rb := len(m.files) - 1
	test := func(i int) bool {
		return pos < m.prefixSizes[i+1]
	}
	for rb-lb > 1 {
		mb := (lb + rb) / 2
		if test(mb) {
			rb = mb
		} else {
			lb = mb
		}
	}
	var currentFileIdx int
	if test(lb) {
		currentFileIdx = lb
	} else {
		currentFileIdx = rb
	}

	posInFile := pos - m.prefixSizes[currentFileIdx]

	posInFile, err := m.files[currentFileIdx].Seek(posInFile, io.SeekStart)
	if err != nil {
		return 0, err
	}

	m.pos = pos
	m.posInFile = posInFile
	m.currentFileIdx = currentFileIdx
	return m.pos, nil
}
