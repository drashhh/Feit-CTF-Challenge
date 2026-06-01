FROM nginx:alpine
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/
COPY index.html /usr/share/nginx/html/
COPY style.css /usr/share/nginx/html/
RUN apk add --no-cache curl
EXPOSE 80
