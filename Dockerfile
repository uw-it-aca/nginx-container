FROM ubuntu:18.04 as nginx-container

WORKDIR /app/
ENV PYTHONUNBUFFERED 1
ENV LOG_FILE stdout

RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get dist-upgrade -y && \
    apt-get clean all && \
    apt-get install -y \
    dumb-init \
    wget \
    python3-venv \
    nginx \
    nodejs \
    npm

RUN python3 -m venv /app/
RUN . /app/bin/activate && \
    wget https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    pip3 install --upgrade pip

RUN wget https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v0.9.0/nginx-prometheus-exporter_0.9.0_linux_386.tar.gz && \
    tar -xf nginx-prometheus-exporter_0.9.0_linux_386.tar.gz && \
    mv nginx-prometheus-exporter /usr/local/bin

RUN . /app/bin/activate && pip install supervisor
RUN mkdir /scripts

ADD conf/supervisord.conf /etc/supervisor/supervisord.conf
ADD conf/nginx.conf /etc/nginx/nginx.conf
ADD scripts/start.sh /scripts

RUN groupadd -r acait -g 1000 && \
    useradd -u 1000 -rm -g acait -d /home/acait -s /bin/bash -c "container user" acait && \
    chown -R acait:acait /app && \
    chown -R acait:acait /home/acait && \
    chmod -R +x /scripts

RUN mkdir /var/run/supervisor && chown -R acait:acait /var/run/supervisor && \
    mkdir /var/run/nginx && chown -R acait:acait /var/run/nginx && \
    chown -R acait:acait /var/lib/nginx && \
    chown -R acait:acait /var/log/nginx && \
    chgrp acait /etc/nginx/nginx.conf && chmod g+w /etc/nginx/nginx.conf

USER acait

RUN . /app/bin/activate &&\
    pip install nodeenv && nodeenv -p &&\
    npm install npm@latest

ENV PORT 8000
ENV ENV localdev

CMD ["dumb-init", "--rewrite", "15:0", "/scripts/start.sh"]

FROM nginx-container as nginx-test-container

# install test tooling
RUN . /app/bin/activate &&\
    npm install jshint -g &&\
    npm install eslint -g &&\
    npm install stylelint -g

ENV NODE_PATH=/app/lib/node_modules
