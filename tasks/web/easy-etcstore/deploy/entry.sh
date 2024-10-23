#!/bin/bash

export ADMIN_PASSWORD=`tr -dc A-Za-z0-9 </dev/urandom | head -c 40; echo `
export ADMIN_USER=admin
export FLAG_KEY="flag_`tr -dc A-Za-z0-9 </dev/urandom | head -c 40; echo `"
/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf