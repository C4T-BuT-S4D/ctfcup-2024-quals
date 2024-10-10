package fs

import (
	"io/fs"
	"time"
)

const GraphName string = "graph.json"

type GraphFile struct {
	MultiReadSeeker
}

type graphFileInfo struct {
	graphFile *GraphFile
}

func (f *graphFileInfo) Name() string {
	return GraphName
}

func (f *graphFileInfo) Size() int64 {
	return f.graphFile.Size()
}

func (f *graphFileInfo) Mode() fs.FileMode {
	return 420
}

func (f *graphFileInfo) ModTime() time.Time {
	return time.Time{}
}

func (f *graphFileInfo) IsDir() bool {
	return false
}

func (f *graphFileInfo) Sys() any {
	return 0
}

func (_ *GraphFile) Close() error {
	return nil
}

func (f *GraphFile) Stat() (fs.FileInfo, error) {
	return &graphFileInfo{graphFile: f}, nil
}
