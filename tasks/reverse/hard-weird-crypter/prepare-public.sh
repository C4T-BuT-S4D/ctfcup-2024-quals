#!/bin/sh
set -e

curdir="$PWD"
pubtemp="$(mktemp -d)"

mkdir "$pubtemp/weird_crypter"
cp dev/weird_crypter "$pubtemp/weird_crypter/"
cp dev/run_dir/flag.txt "$pubtemp/weird_crypter"
cp dev/run_dir/key.bin "$pubtemp/weird_crypter"

cd "$pubtemp"

zip -9 -r weird_crypter.zip weird_crypter

cd "$curdir"
mv "$pubtemp/weird_crypter.zip" public

rm -rf "$pubtemp"
