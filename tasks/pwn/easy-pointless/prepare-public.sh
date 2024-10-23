#!/bin/sh
set -e

curdir="$PWD"
pubtemp="$(mktemp -d)"

mkdir "$pubtemp/pointless"
cp dev/src/pointless.c "$pubtemp/pointless/"
cp deploy/pointless "$pubtemp/pointless/"
cp deploy/Dockerfile "$pubtemp/pointless/"
cp deploy/entrypoint.sh "$pubtemp/pointless"

cd "$pubtemp"

zip -9 -r pointless.zip pointless

cd "$curdir"
mv "$pubtemp/pointless.zip" public

rm -rf "$pubtemp"
