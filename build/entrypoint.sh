#!/usr/bin/env sh
set -eu

envsubst < /etc/nginx/nginx.conf.tmpl > /etc/nginx/nginx.conf
exec "$@"
