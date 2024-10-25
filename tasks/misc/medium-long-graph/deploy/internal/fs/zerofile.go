package fs

import (
	"fmt"
	"io"
)

const ZeroFmt string = "\"%v\": {\"connected\": []}, "

type zeroFileRange struct {
	start int64
	end   int64
	elLen int64
}
type ZeroFile struct {
	start     int64
	end       int64
	pos       int64
	totalSize int64
	ranges    []zeroFileRange
}

func nextPowerOfTen(n int64) int64 {
	if n == 0 {
		return 10
	}

	log10 := 0
	for ; n > 0; log10++ {
		n /= 10
	}

	res := int64(1)

	for i := 0; i < log10+1; i++ {
		res *= 10
	}

	return res
}

func (r *zeroFileRange) Len() int64 {
	return r.end - r.start
}

func (r *zeroFileRange) TotalSize() int64 {
	return r.Len() * r.elLen
}

func NewZeroFile(start, end int64) *ZeroFile {
	ranges := make([]zeroFileRange, 0)

	for start != end {
		powerOfTen := nextPowerOfTen(start)
		ranges = append(ranges, zeroFileRange{
			start: start,
			end:   min(powerOfTen, end),
			elLen: int64(len(fmt.Sprintf(ZeroFmt, start))),
		})

		start = min(powerOfTen, end)
	}

	totalSize := int64(0)
	for _, r := range ranges {
		totalSize += r.elLen * (r.end - r.start)
	}

	return &ZeroFile{
		start:     start,
		end:       end,
		pos:       0,
		totalSize: totalSize,
		ranges:    ranges,
	}
}

func (f *ZeroFile) Read(p []byte) (int, error) {
	rangeIdx := int64(0)

	sizeSoFar := int64(0)
	broken := false
	for ; rangeIdx < int64(len(f.ranges)); rangeIdx++ {
		if sizeSoFar+f.ranges[rangeIdx].TotalSize() >= f.pos {
			broken = true
			break
		}
		sizeSoFar += f.ranges[rangeIdx].TotalSize()
	}

	if !broken {
		return 0, io.EOF
	}

	nRead := 0

	inRangeIdx := (f.pos - sizeSoFar) / f.ranges[rangeIdx].elLen
	posNorm := inRangeIdx*f.ranges[rangeIdx].elLen + sizeSoFar
	if f.pos != posNorm {
		formatted := fmt.Sprintf(ZeroFmt, inRangeIdx+f.ranges[rangeIdx].start)
		for ; nRead < len(p) && f.pos < posNorm+f.ranges[rangeIdx].elLen; nRead++ {
			p[nRead] = formatted[f.pos-posNorm]
			f.pos++

		}
		inRangeIdx++
	}

	for ; nRead < len(p); inRangeIdx++ {
		if inRangeIdx >= f.ranges[rangeIdx].Len() {
			inRangeIdx = 0
			rangeIdx++
		}

		if rangeIdx >= int64(len(f.ranges)) {
			break
		}

		formatted := fmt.Sprintf(ZeroFmt, inRangeIdx+f.ranges[rangeIdx].start)
		for j := 0; nRead < len(p) && j < len(formatted); j++ {
			p[nRead] = formatted[j]
			nRead++
			f.pos++
		}
	}

	if nRead == 0 {
		return 0, io.EOF
	}

	return nRead, nil
}

func (f *ZeroFile) Seek(offset int64, whence int) (int64, error) {
	pos := f.pos
	if whence == io.SeekStart {
		pos = offset
	} else if whence == io.SeekEnd {
		pos = f.totalSize + offset
	} else if whence == io.SeekCurrent {
		pos += offset
	} else {
		return 0, io.EOF
	}
	if 0 > pos || pos >= f.totalSize {
		return 0, io.EOF
	}

	f.pos = pos
	return pos, nil
}

func (f *ZeroFile) Size() int64 {
	return f.totalSize
}
