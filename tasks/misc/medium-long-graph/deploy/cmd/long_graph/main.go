package main

import (
	"bytes"
	"fmt"
	"long_graph/internal/fs"
	"math/rand"
	"net/http"
	"os"
	"slices"
	"sort"
	"strings"
)

const (
	GraphPoints         int64 = 1125899906842614
	GraphActualVertices int64 = 100
	GraphEdges          int64 = 1000
)

type Vertex struct {
	ID        int64
	Connected []int64
	Flag      *string
}

type Graph []Vertex

func GenerateGraph(points, actualVertices, edges int64) Graph {
	graph := make(map[int64]*Vertex)

	vertices := Graph{}
	vertices = append(vertices, Vertex{
		ID: 0,
	})
	graph[0] = &vertices[0]
	for len(graph) < int(actualVertices) {
		v := rand.Int63n(points)
		if _, ok := graph[v]; !ok {
			vertices = append(vertices, Vertex{
				ID: v,
			})
			graph[v] = &vertices[len(vertices)-1]
		}
	}

	flag := os.Getenv("FLAG")
	vertices[len(vertices)-1].Flag = &flag
	for i := 1; i < len(vertices); i++ {
		u := rand.Intn(i)
		vertices[i].Connected = append(vertices[i].Connected, vertices[u].ID)
		vertices[u].Connected = append(vertices[u].Connected, vertices[i].ID)
	}

	edgeCount := len(vertices) - 1

	for edgeCount < int(GraphEdges) {
		v := rand.Intn(len(vertices))
		u := rand.Intn(len(vertices))
		if !slices.Contains(vertices[v].Connected, vertices[u].ID) {
			vertices[v].Connected = append(vertices[v].Connected, vertices[u].ID)
			vertices[u].Connected = append(vertices[u].Connected, vertices[v].ID)
			edgeCount++
		}
	}

	return vertices
}

func MarshalVertex(v *Vertex) []byte {
	res := []byte(fmt.Sprintf("\"%v\": {", v.ID))
	if v.Flag != nil {
		res = fmt.Appendf(res, "\"flag\": \"%s\", ", *v.Flag)
	}

	connectedStrings := make([]string, len(v.Connected))
	for i, c := range v.Connected {
		connectedStrings[i] = fmt.Sprintf("\"%v\"", c)
	}
	res = fmt.Appendf(res, "\"connected\": [%s] }, ", strings.Join(connectedStrings, ", "))

	return res
}

func GraphToGraphFile(graph Graph) *fs.GraphFile {
	graph = slices.Clone(graph)
	sort.Slice(graph, func(i, j int) bool {
		return graph[i].ID < graph[j].ID
	})

	files := make([]fs.SizedReadSeeker, 0)
	files = append(files, bytes.NewReader([]byte("{")))
	files = append(files, bytes.NewReader(MarshalVertex(&graph[0])))

	for i := 1; i < len(graph); i++ {
		if graph[i-1].ID+1 != graph[i].ID {
			files = append(files, fs.NewZeroFile(graph[i-1].ID+1, graph[i].ID))
		}
		files = append(files, bytes.NewReader(MarshalVertex(&graph[i])))
	}

	if graph[len(graph)-1].ID != GraphPoints {
		files = append(files, fs.NewZeroFile(graph[len(graph)-1].ID+1, GraphPoints-1))
	}

	files = append(files, bytes.NewReader([]byte(fmt.Sprintf("\"%v\": {\"connected\": []}", GraphPoints))))
	files = append(files, bytes.NewReader([]byte("}")))
	return &fs.GraphFile{
		MultiReadSeeker: *fs.NewMultiReadSeeker(files),
	}
}

func main() {
	graph := GenerateGraph(GraphPoints, GraphActualVertices, GraphEdges)

	m := &http.ServeMux{}
	m.HandleFunc("/graph.json", func(w http.ResponseWriter, r *http.Request) {
		graphFile := GraphToGraphFile(graph)
		myfs := fs.NewCustomFS(graphFile)
		http.ServeFileFS(w, r, myfs, "graph.json")
	})
	if err := http.ListenAndServe(":7117", m); err != nil {
		panic(err)
	}
}
