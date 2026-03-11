FROM ubuntu:24.04 as nginx-container

WORKDIR /app/
ENV PYTHONUNBUFFERED 1
ENV TZ America/Los_Angeles
ENV LOG_FILE stdout

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y && \
  apt-get upgrade -y && \
  apt-get dist-upgrade -y && \
  apt-get clean && \
  apt-get install -y \
  dumb-init \
  nginx \
  nodejs \
  npm \
  python3-venv \
  python3-pip \
  supervisor \
  wget && \
  rm -rf /var/lib/apt/lists

RUN python3 -m venv /app/

RUN wget https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v0.10.0/nginx-prometheus-exporter_0.10.0_linux_386.tar.gz && \
  tar -xf nginx-prometheus-exporter_0.10.0_linux_386.tar.gz && \
  mv nginx-prometheus-exporter /usr/local/bin

COPY conf/supervisord.conf /etc/supervisor/supervisord.conf
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/locations.conf /etc/nginx/includes/locations.conf
COPY scripts /scripts

# Override default ubuntu user with acait
RUN usermod -l acait -d /home/acait -m ubuntu && \
  groupmod -n acait ubuntu && \
  chown -R acait:acait /app /home/acait && \
  chmod -R +x /scripts

RUN mkdir /var/run/supervisor && chown -R acait:acait /var/run/supervisor && \
  mkdir /var/run/nginx && chown -R acait:acait /var/run/nginx && \
  chown -R acait:acait /var/lib/nginx && \
  chown -R acait:acait /var/log/nginx && \
  chgrp acait /etc/nginx/nginx.conf && chmod g+w /etc/nginx/nginx.conf

USER acait

RUN . /app/bin/activate && \
  pip install nodeenv && nodeenv -p && \
  npm install npm@latest

ENV PORT 8000
ENV ENV localdev

CMD ["dumb-init", "--rewrite", "15:0", "/scripts/start.sh"]

FROM nginx-container as nginx-test-container

# install test tooling
RUN . /app/bin/activate && \
  npm install jshint -g && \
  npm install eslint -g && \
  npm install stylelint -g

ENV NODE_PATH=/app/lib/node_modules
