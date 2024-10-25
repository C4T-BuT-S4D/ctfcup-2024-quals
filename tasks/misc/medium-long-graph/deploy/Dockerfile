FROM golang:1.23.2-alpine AS builder

WORKDIR /build
COPY go.mod .
COPY go.sum .
RUN go mod download

COPY cmd cmd
COPY internal internal
RUN go build -o long_graph cmd/long_graph/main.go

FROM scratch

COPY --from=builder /build/long_graph long_graph

CMD ["./long_graph"]
