#!/bin/bash

# Set the port for nginx
sed 's/${PORT}/'$PORT'/g' /etc/nginx/nginx.conf > /tmp/nginx.tmp
cat /tmp/nginx.tmp > /etc/nginx/nginx.conf

# Start nginx
exec /app/bin/supervisord -c /etc/supervisor/supervisord.conf -n
