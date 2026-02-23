#!/bin/sh
set -e

# Default UI_PORT if not set (Next.js default is 8080)
export UI_PORT="${UI_PORT:-8080}"

# Get DNS resolver from /etc/resolv.conf (Railway's DNS server)
export DNS_RESOLVER=$(awk '/^nameserver/ {print $2; exit}' /etc/resolv.conf)
echo "Using DNS resolver: ${DNS_RESOLVER}"

# Render nginx config using env vars
envsubst '${PORT} ${KRATOS_INTERNAL} ${UI_INTERNAL} ${UI_PORT} ${KETO_INTERNAL} ${DNS_RESOLVER}' \
  < /etc/nginx/templates/nginx.conf.template \
  > /etc/nginx/nginx.conf

exec nginx -g 'daemon off;'
