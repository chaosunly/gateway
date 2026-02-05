#!/bin/sh
set -e

# Render nginx config using env vars
envsubst '${PORT} ${KRATOS_INTERNAL} ${KRATOS_ADMIN_INTERNAL} ${ADMIN_UI_INTERNAL} ${UI_INTERNAL}' \
  < /etc/nginx/templates/nginx.conf.template \
  > /etc/nginx/nginx.conf

exec nginx -g 'daemon off;'
