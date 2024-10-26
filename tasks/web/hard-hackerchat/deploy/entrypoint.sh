#!/bin/bash

export ADMIN_PASSWORD="$(openssl rand -hex 14)"
echo $ADMIN_PASSWORD > /app/admin_pass

su - postgres -c "/usr/lib/postgresql/14/bin/postgres --single --config-file=/etc/postgresql/14/main/postgresql.conf <<< \"ALTER USER postgres WITH PASSWORD '$PGPASSWORD';\""
su - postgres -c "/usr/lib/postgresql/14/bin/postgres --single --config-file=/etc/postgresql/14/main/postgresql.conf <<< \"create database chats;\""

/usr/bin/supervisord -c /etc/supervisor/supervisord.conf
