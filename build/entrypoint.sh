#!/usr/bin/env sh
set -eu

envsubst '${BASE_DOMAIN},${PORT}' < /etc/nginx/nginx.conf.tmpl > /etc/nginx/nginx.conf
exec "$@"
