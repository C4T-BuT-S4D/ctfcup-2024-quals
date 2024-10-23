FROM ubuntu@sha256:8a37d68f4f73ebf3d4efafbcf66379bf3728902a8038616808f04e34a9ab63ee

RUN apt update
RUN apt install -y socat

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
COPY pointless /
RUN chmod +x /pointless

CMD ["/entrypoint.sh"]
