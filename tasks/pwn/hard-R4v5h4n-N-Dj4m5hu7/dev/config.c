#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>
#include <dirent.h>
#include <string.h>
#include <limits.h>

#include "config.h"
#include "util.h"

ino_t *banned_files = (ino_t*)NULL;
int banned_files_count = 0;
char flag_path[PATH_MAX];

void add_banned_file (ino_t f_inode, int *buff_inode_count) {
	child_printf("Adding banned inode %u\n", f_inode);
	banned_files[banned_files_count] = f_inode;
	banned_files_count++;
	if (banned_files_count == *buff_inode_count)
	{
		ino_t *buff1 = calloc(sizeof(ino_t), (*buff_inode_count)*2);
		memcpy(buff1, banned_files, sizeof(ino_t)*(*buff_inode_count));
		(*buff_inode_count) *= 2;
		free(banned_files);
		banned_files = buff1;
	}
}

void add_banned_directory (char *f_path, int *buff_inode_count) {
	child_printf("Adding directory %s to blacklist\n", f_path);
	DIR *dir = opendir(f_path);
	if (dir == NULL){
		return;
		//check_err(-1, "Failed to open directory %s\n", f_path);
	}
	struct dirent *entry;
	while ((entry = readdir(dir)) != NULL) {
		if (strcmp(entry->d_name, "..") == 0 || strcmp(entry->d_name, ".") == 0)
			continue;

		if (entry->d_type == DT_DIR)
		{
			char *d_path = file_in_dir(f_path, entry->d_name);
			child_printf("Subdirectory %s path %s\n", entry->d_name, d_path);
			add_banned_directory(d_path, buff_inode_count);
			free(d_path);
		}
		else
		{
			child_printf("Adding to blacklist file %s\n", entry->d_name);
			add_banned_file(entry->d_ino, buff_inode_count);
		}
	}
}

void load_config () {
	int fsize = 0, buff_inode_count = 128;

	child_printf("There is no functionality to somehow change flag_file_path, but it will be added later\n");
	child_printf("That's why it is being opened for READ/WRITE\n");
	int fgpath_fd = open("/home/task/flag_file_path", O_RDWR);
	read(fgpath_fd, flag_path, PATH_MAX);

	char *config = read_file(CONFIG_PATH, &fsize), *line = NULL;
	banned_files = calloc(sizeof(ino_t), buff_inode_count);
	
	child_printf("%s\nazaza\n", config);

	line = config;

	while (*line) {
		char *newline = strchr(line, '\n');
		if (newline == NULL)
			newline = &line[strlen(line)];
		*newline = '\0';

		child_printf("Adding %s to blacklist\n", line);
		struct stat f_info;
		stat(line, &f_info);
		if (S_ISDIR(f_info.st_mode)) {
			child_printf("Disallowed directory: %s\n", line);
			add_banned_directory(line, &buff_inode_count);
		}
		else {
			child_printf("Disallowed file: %s\n", line);
			add_banned_file(f_info.st_ino, &buff_inode_count);
		}
		line = newline+1;
	}
}