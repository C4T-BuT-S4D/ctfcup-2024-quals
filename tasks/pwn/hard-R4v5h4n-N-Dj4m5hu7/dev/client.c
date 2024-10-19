#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <stdarg.h>
#include <unistd.h>

#include "util.h"

#define SOCKET_PATH "/home/task/log_socket"

void error_printf(char *fmt, ...) 
{    
	va_list argptr;
	va_start(argptr,fmt);
	vprintf(fmt, argptr);
	va_end(argptr);
	exit(-1);
}

pid_t child_pid;

void send_user_input (char *s, int sockfd) {
	char query[4096];
	puts(s);
	fgets(query, sizeof(query)-1, stdin);
	char *newlineptr = strrchr(query, '\n');
	if (newlineptr != NULL)
		*newlineptr = '\0';
	int size = strlen(query)+1;
	check_err(send(sockfd, &size, 4, 0), "Connection closed");
	check_err(send(sockfd, query, size, 0), "Connection closed");
}

int main (int argc, char **argv) {
	struct msghdr msg = { 0 };
	struct iovec iovs[1];
	char *buff = malloc(1024*1024);
	iovs[0].iov_base = buff;
	iovs[0].iov_len = 1024*1024;
	msg.msg_iov = iovs;
	msg.msg_iovlen = 1;

	int sockfd = socket(AF_UNIX, SOCK_STREAM, 0);
	struct sockaddr_un s_addr = { .sun_family = AF_UNIX };
	strncpy(s_addr.sun_path, SOCKET_PATH, sizeof(s_addr.sun_path) - 1);
	
	int ret = connect(sockfd, (struct sockaddr*)&s_addr, sizeof(s_addr));
	if (ret < 0)
		error_printf("Unable connect to socket at path %s\n", SOCKET_PATH);

	puts("This program is grep analog for filtering logs on remote server");
	while (1)
	{
		send_user_input("Enter path:", sockfd);
		send_user_input("Enter substring:", sockfd);
		while (1) {
			ssize_t idx = recvmsg(sockfd, &msg, 0);
			if (strncmp(buff, "exit", 4) == 0)
				break;
			buff[idx] = '\0';
			puts(buff);
			//printf("Comparings %s with exit\n", buff);
		}
	}

	close(sockfd);
	return 0;
}