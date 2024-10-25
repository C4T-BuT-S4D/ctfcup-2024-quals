#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>

extern pid_t child_pid;

int check_err(int ret, char *fmt, ...) {
	if (ret != -1)
		return ret;

	va_list argptr;
	va_start(argptr,fmt);
	vprintf(fmt, argptr);
	va_end(argptr);
	exit(-1);
	return -1;
}

void child_printf(char *fmt, ...) {
	va_list argptr;
	va_start(argptr,fmt);
	printf("CHILD:%d ", child_pid);
	vprintf(fmt, argptr);
	va_end(argptr);
}

char* read_file(char *f_path, int *file_size) {
	int fd = check_err(open(f_path, O_RDONLY), "Failed while opening file %s\n", f_path);
	*file_size = 0;
	int buff_size = 1024*1024;
	char *buff = calloc(1, buff_size);
	ssize_t readed;
	while (readed = read(fd, &buff[*file_size], buff_size-(*file_size)))
	{
		*file_size+=readed;
		if (*file_size == buff_size) {
			char *buff1 = calloc(buff_size, 2);
			memcpy(buff1, buff, buff_size);
			buff_size *= 2;
			free(buff);
			buff = buff1;
		}
		else {
			break;
		}
	}
	//close(fd);
	//child_printf("Readed %s\n%s\n", f_path, buff);
	return buff;
}

char *file_in_dir (char *dir, char *file) {
	char *d_path = calloc(1, strlen(dir)+strlen(file)+2);
	strcat(d_path, dir);
	strcat(d_path, "/");
	strcat(d_path, file);
	return d_path;
}