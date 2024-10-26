#!/bin/sh
set -e

curdir="$PWD"
pubtemp="$(mktemp -d)"

mkdir "$pubtemp/just_bfs"
cp deploy/OCRB.ttf "$pubtemp/just_bfs/"
cp deploy/generate.py "$pubtemp/just_bfs/"
cp deploy/olymp_problem.py "$pubtemp/just_bfs"
cp deploy/Dockerfile "$pubtemp/just_bfs"
cp deploy/requirments.txt "$pubtemp/just_bfs"

cd "$pubtemp"

zip -9 -r just_bfs.zip just_bfs

cd "$curdir"
mv "$pubtemp/just_bfs.zip" public

rm -rf "$pubtemp"
