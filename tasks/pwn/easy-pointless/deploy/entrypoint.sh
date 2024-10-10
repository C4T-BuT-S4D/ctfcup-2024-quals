#!/bin/sh

echo "$FLAG" >/flag-"$(tr -dc 'a-f0-9' </dev/urandom | head -c32)".txt

unset FLAG

socat 'TCP-LISTEN:3113,reuseaddr,fork' 'EXEC:/pointless'
