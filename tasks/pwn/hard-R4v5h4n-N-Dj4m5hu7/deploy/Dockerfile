FROM ubuntu:24.04
RUN useradd -m -s /bin/bash ssh_user
RUN useradd -m -s /bin/bash task
RUN echo "ssh_user:password" | chpasswd

COPY server server.cfg flag_file_path /home/task/
RUN chown task:task /home/task/*
RUN chmod o+x /home/task/
RUN chmod -R o+r /home/task/
RUN chmod o-w /home/task/*
RUN chmod +s /home/task/server
RUN chmod o+x /home/task/server

COPY client /home/ssh_user/
RUN chmod +x /home/ssh_user/client

RUN apt-get update
RUN apt-get install -y openssh-server
RUN echo "PORT 1313" >> /etc/ssh/sshd_config
RUN echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
RUN echo "PermitRootLogin no" >> /etc/ssh/sshd_config
RUN mkdir -p /run/sshd
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
