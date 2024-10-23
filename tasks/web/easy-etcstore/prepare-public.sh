#!/bin/bash

set -ex

rm -rf etcstore public/etcstore.tar.gz
mkdir -p etcstore

cp -r deploy/* etcstore/

tar -cvf etcstore.tar ./etcstore/* && gzip -9 etcstore.tar
mv etcstore.tar.gz public/

rm -rf etcstore/