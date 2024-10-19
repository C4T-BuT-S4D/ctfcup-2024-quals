#ifndef config_h
#define config_h

#include <sys/stat.h>
#include <stddef.h>
#include <limits.h>

#define CONFIG_PATH "/home/task/server.cfg"

extern ino_t *banned_files;
extern int banned_files_count;
extern char flag_path[PATH_MAX];
void load_config ();


#endif