# FROM ghcr.io/puppeteer/puppeteer:23.6.0

# USER root

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update \
    && apt install -yq gnupg2 curl sqlite3 socat xxd hashcash

# https://github.com/puppeteer/puppeteer/blob/main/docs/troubleshooting.md
RUN curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && apt update \
    && apt install -yq --no-install-recommends gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgbm1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libnss3 lsb-release xdg-utils \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt install -y nodejs

ENV PUPPETEER_SKIP_DOWNLOAD=true

WORKDIR /tmp/bot

RUN npm install puppeteer \
    && npx puppeteer browsers install chrome@130.0.6723.58


ADD bot.js /tmp/bot/bot.js

ADD entry.sh /entry.sh

CMD [ "/entry.sh" ]