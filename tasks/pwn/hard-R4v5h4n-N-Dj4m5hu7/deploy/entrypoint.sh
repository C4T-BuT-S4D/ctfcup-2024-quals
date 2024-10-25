#!/bin/sh

FLAG_FILE_PATH=/home/task/flag

echo "$FLAG" >"$FLAG_FILE_PATH"
chown task:task "$FLAG_FILE_PATH"
chmod o-r "$FLAG_FILE_PATH"

unset FLAG

/usr/sbin/sshd -D
