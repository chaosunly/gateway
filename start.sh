#!/bin/sh
set -e

# Set defaults for optional variables if not provided
: ${ADMIN_UI_INTERNAL:=http://ory-admin-ui.railway.internal:8080}

# Render nginx config using env vars
envsubst '${PORT} ${KRATOS_INTERNAL} ${KRATOS_ADMIN_INTERNAL} ${ADMIN_UI_INTERNAL} ${UI_INTERNAL}' \
  < /etc/nginx/templates/nginx.conf.template \
  > /etc/nginx/nginx.conf

exec nginx -g 'daemon off;'
