#!/bin/bash

set -ex

rm -rf hackerchat public/hackerchat.tar.gz
mkdir -p hackerchat

cp -r deploy/ hackerchat/

tar -cvf hackerchat.tar ./hackerchat/ && gzip -9 hackerchat.tar
mv hackerchat.tar.gz public/

rm -rf hackerchat/

