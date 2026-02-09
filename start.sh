#!/bin/sh
set -e

# Render nginx config using env vars
envsubst '${PORT} ${KRATOS_INTERNAL} ${UI_INTERNAL} ${KETO_INTERNAL}' \
  < /etc/nginx/templates/nginx.conf.template \
  > /etc/nginx/nginx.conf

exec nginx -g 'daemon off;'
