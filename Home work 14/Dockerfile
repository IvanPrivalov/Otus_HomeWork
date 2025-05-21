FROM alpine:3.20
RUN apk update && apk add nginx \
&& rm -rf /var/cache/apk/*
RUN adduser -D -g 'webuser' webuser \
&& mkdir /webuser \
&& chown -R webuser:webuser /var/lib/nginx \
&& chown -R webuser:webuser /webuser \
&& mkdir -p /run/nginx
COPY nginx.conf /etc/nginx
COPY index.html /webuser
EXPOSE 80
ENTRYPOINT ["nginx", "-g", "daemon off;"]