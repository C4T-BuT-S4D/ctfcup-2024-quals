#!/bin/bash

set -ex

rm -rf konstruktor public/konstruktor.tar.gz
mkdir -p konstruktor

cp -r deploy/ konstruktor/
mv konstruktor/.local.env konstruktor/.env

tar -cvf konstruktor.tar ./konstruktor/ && gzip -9 konstruktor.tar
mv konstruktor.tar.gz public/

rm -rf konstruktor/