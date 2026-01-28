FROM nginx:alpine

RUN apk add --no-cache bash gettext

COPY nginx.conf.template /etc/nginx/templates/nginx.conf.template
COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
