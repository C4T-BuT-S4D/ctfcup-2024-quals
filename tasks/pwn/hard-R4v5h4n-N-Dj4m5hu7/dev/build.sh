killall -9 server 2>/dev/null
killall -9 client 2>/dev/null
gcc server.c config.c config.h util.c util.h -o server -T linker_script.ld
gcc client.c util.c util.h -o client -w
