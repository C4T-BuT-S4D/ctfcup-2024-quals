FROM golang:1.23 AS build-stage

WORKDIR /app

COPY src .

RUN go mod download

RUN CGO_ENABLED=0 GOOS=linux go build -o /app/server

FROM debian:bullseye-slim

COPY --from=build-stage /app/server /server

RUN apt-get update && apt-get install -y supervisor etcd
RUN mkdir -p /var/log/supervisor
COPY conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]