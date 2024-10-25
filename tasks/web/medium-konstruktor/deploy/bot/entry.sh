#!/bin/bash

socat TCP-LISTEN:31338,reuseaddr,fork SYSTEM:"timeout -s SIGKILL 600 node /tmp/bot/bot.js"