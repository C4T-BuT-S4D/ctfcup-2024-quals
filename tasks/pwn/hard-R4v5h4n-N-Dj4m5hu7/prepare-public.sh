#!/bin/sh
set -e

curdir="$PWD"
pubtemp="$(mktemp -d)"

mkdir "$pubtemp/R4v5h4n"
cp deploy/Dockerfile "$pubtemp/R4v5h4n/"
cp deploy/entrypoint.sh "$pubtemp/R4v5h4n/"
cp deploy/server "$pubtemp/R4v5h4n"
cp deploy/client "$pubtemp/R4v5h4n"
cp deploy/server.cfg "$pubtemp/R4v5h4n"
cp deploy/flag_file_path "$pubtemp/R4v5h4n"

cd "$pubtemp"

zip -9 -r R4v5h4n.zip R4v5h4n

cd "$curdir"
mv "$pubtemp/R4v5h4n.zip" public

rm -rf "$pubtemp"
