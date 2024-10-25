#include <dirent.h>
#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/un.h>
#include <unistd.h>

#include "config.h"
#include "util.h"

pid_t child_pid;
char substr[256] __attribute__((section("my_section")));
char path[256] __attribute__((section("my_section")));
struct msghdr msg __attribute__((section("my_section")));

#define SOCKET_PATH "/home/task/log_socket"

void check_if_file_allowed_inode(ino_t inode) {
  child_printf("Checking if inode %u in list of banned files\n", inode);
  child_printf("Banned files count: %u\n", banned_files_count);
  for (int i = 0; i < banned_files_count; i++) {
    // child_printf("comparing with inode %u\n", banned_files[i]);
    if (banned_files[i] == inode)
      check_err(-1, "File banned!!!");
  }
}

void check_if_file_allowed(char *f_path) {
  struct stat f_info;
  stat(f_path, &f_info);
  check_if_file_allowed_inode(f_info.st_ino);
}

void process_file(char *f_path, int conn_fd) {
  child_printf("Processing file %s\n", f_path);

  char absolute_path[PATH_MAX];
  realpath(f_path, absolute_path);
  child_printf("Real path %s\n", absolute_path);
  if (strncmp(absolute_path, flag_path, strlen(absolute_path)) == 0) {
    check_err(-1, "flag file is forever banned, no matter if it is specified "
                  "in config or not\n");
  }

  int file_size = 0, iov_arr_size = 128, lines_found = 0;
  char *data, *line = NULL;
  struct iovec *iov_arr = calloc(sizeof(struct iovec), iov_arr_size);

  data = read_file(f_path, &file_size);

  //	child_printf("Read file of size %u\n%s\n", file_size, data);

  for (int i = 0; i < file_size; i++) {
    if (line == NULL)
      line = &data[i];

    if (data[i] == '\n') {
      data[i] = '\0';
      if (strstr(line, substr)) {
        child_printf("Found string %s\n", line);
        iov_arr[lines_found].iov_base = line;
        iov_arr[lines_found].iov_len = strlen(line) + 1;
        lines_found++;
        data[i] = '\n';
        if (lines_found == iov_arr_size) {
          struct iovec *new_iov_arr =
              calloc(sizeof(struct iovec), iov_arr_size * 2);
          memcpy(new_iov_arr, iov_arr, sizeof(struct iovec) * iov_arr_size);
          free(iov_arr);
          iov_arr = new_iov_arr;
          iov_arr_size *= 2;
        }
      }
      line = NULL;
    }
  }

  msg.msg_iov = iov_arr;
  msg.msg_iovlen = lines_found;
  sendmsg(conn_fd, &msg, 0);
  free(data);
  free(iov_arr);
}

void process_directory(char *f_path, int conn_fd) {
  child_printf("Processing directory %s\n", f_path);
  DIR *dir = opendir(f_path);
  struct dirent *entry;
  while ((entry = readdir(dir)) != NULL) {
    if (strcmp(entry->d_name, "..") == 0 || strcmp(entry->d_name, ".") == 0)
      continue;
    child_printf("Processing %s\n", entry->d_name);

    char *path = file_in_dir(f_path, entry->d_name);

    if (entry->d_type == DT_DIR)
      process_directory(path, conn_fd);
    else if (entry->d_type != DT_SOCK) {
      check_if_file_allowed_inode(entry->d_ino);
      process_file(path, conn_fd);
    }
    free(path);
  }
}

void receive_str(int conn_fd, char *buff) {
  int size = 0;
  check_err(
      recv(conn_fd, &size, 4, 0),
      "Got error while receiving data, it seems like client disconnected\n");
  if (size > 256) {
    check_err(-1, "Size is too big\n");
  }
  recv(conn_fd, buff, size, 0);
}

void handle_connection(int conn_fd) {
  child_pid = getpid();
  load_config();

  while (1) {
    receive_str(conn_fd, path);
    receive_str(conn_fd, substr);
    child_printf("Searching substring %s in %s\n", substr, path);

    struct stat f_info;
    check_err(stat(path, &f_info), "Error while getting info about file");

    if (S_ISDIR(f_info.st_mode)) {
      // child_printf("User sent path to directory\n");
      process_directory(path, conn_fd);
    } else {
      // child_printf("User sent path to file\n");
      check_if_file_allowed(path);
      process_file(path, conn_fd);
    }
    struct iovec _v = {.iov_base = "exit", .iov_len = 4};
    msg.msg_iov = &_v;
    msg.msg_iovlen = 1;
    sleep(1);
    write(conn_fd, 0, 0);
    sendmsg(conn_fd, &msg, 0);
  }
}

int main(int argc, char **argv) {
  int sockfd = socket(AF_UNIX, SOCK_STREAM, 0);
  struct sockaddr_un s_addr = {.sun_family = AF_UNIX}, client_addr = {0};
  strncpy(s_addr.sun_path, SOCKET_PATH, sizeof(s_addr.sun_path) - 1);

  unlink(SOCKET_PATH);
  mode_t umask_ = umask(0000);
  check_err(bind(sockfd, (struct sockaddr *)&s_addr, sizeof(s_addr)),
            "Unable to bind socket at path %s\n", SOCKET_PATH);
  umask(umask_);
  check_err(listen(sockfd, 99), "Unable to start listening socket");
  // stat f_info;
  // stat();

  puts("Successfully binded socket, waiting for connections");
  while (1) {
    int conn_fd =
        check_err(accept(sockfd, NULL, NULL),
                  "Something went wrong while accepting connection\n");
    printf("Got connection, file descriptor: %u\n", conn_fd);
    puts("Forking");
    pid_t p = check_err(fork(), "Error occured while trying to fork");
    if (p == 0) {
      handle_connection(conn_fd);
    }
  }

  close(sockfd);
  unlink(SOCKET_PATH);
  return 0;
}
