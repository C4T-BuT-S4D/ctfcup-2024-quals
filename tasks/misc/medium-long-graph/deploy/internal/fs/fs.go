package fs

import (
	"io/fs"
	"strings"
)

type CustomFS struct {
	graphFile *GraphFile
}

func NewCustomFS(graphFile *GraphFile) *CustomFS {
	return &CustomFS{
		graphFile: graphFile,
	}
}

func (myfs *CustomFS) Open(name string) (fs.File, error) {
	if strings.TrimLeft(strings.ReplaceAll(name, "/../", ""), "/") == GraphName {
		return myfs.graphFile, nil
	}
	return nil, fs.ErrNotExist
}
