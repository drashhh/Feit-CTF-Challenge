FROM nginx:alpine
RUN apk add --no-cache curl
COPY nginx.conf /etc/nginx/nginx.conf
COPY website/ /usr/share/nginx/html/
RUN chmod -R 755 /usr/share/nginx/html/
EXPOSE 80
