#!/bin/sh
set -e

curdir="$PWD"
pubtemp="$(mktemp -d)"

mkdir "$pubtemp/olymp"
cp dev/a.cc "$pubtemp/olymp/"
cp deploy/a.out "$pubtemp/olymp/"
cp deploy/Dockerfile "$pubtemp/olymp/"
cp deploy/entrypoint.sh "$pubtemp/olymp"

cd "$pubtemp"

zip -9 -r olymp.zip olymp

cd "$curdir"
mv "$pubtemp/olymp.zip" public

rm -rf "$pubtemp"
