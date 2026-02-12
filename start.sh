#!/bin/sh
set -e

export UI_PORT="${UI_PORT:-8080}"

envsubst '${PORT} ${KRATOS_INTERNAL} ${UI_INTERNAL} ${UI_PORT} ${KETO_INTERNAL} ${HYDRA_INTERNAL}' \
  < /etc/nginx/templates/nginx.conf.template \
  > /etc/nginx/nginx.conf

exec nginx -g 'daemon off;'