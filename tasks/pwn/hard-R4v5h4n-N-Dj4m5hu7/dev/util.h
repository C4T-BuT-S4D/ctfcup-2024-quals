#ifndef util_h
#define util_h

int check_err(int ret, char *fmt, ...);
void child_printf(char *fmt, ...);
char* read_file(char *f_path, int *file_size);
char *file_in_dir (char *dir, char *file);
#endif