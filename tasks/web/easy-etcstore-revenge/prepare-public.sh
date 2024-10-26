#!/bin/bash

set -ex

rm -rf etcstore-revenge public/etcstore-revenge.tar.gz
mkdir -p etcstore-revenge

cp -r deploy/* etcstore-revenge/

tar -cvf etcstore-revenge.tar ./etcstore-revenge/* && gzip -9 etcstore-revenge.tar
mv etcstore-revenge.tar.gz public/

rm -rf etcstore-revenge/
