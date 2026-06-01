FROM alpine:3.18

RUN apk add --no-cache nginx vsftpd supervisor curl

# Nginx config
RUN rm /etc/nginx/conf.d/default.conf || true
COPY nginx.conf /etc/nginx/nginx.conf

# vsftpd config
COPY vsftpd.conf /etc/vsftpd/vsftpd.conf

# Supervisord config
COPY supervisord.conf /etc/supervisord.conf

# Website files
COPY website/ /usr/share/nginx/html/
RUN chmod -R 755 /usr/share/nginx/html && \
    chmod 644 /usr/share/nginx/html/robots.txt

# FTP files
RUN mkdir -p /srv/ftp/.backup
COPY ftp/.backup/admin_notes.txt /srv/ftp/.backup/
RUN chmod -R 555 /srv/ftp && \
    chown -R ftp:ftp /srv/ftp && \
    mkdir -p /var/empty

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80 21 30000-30009

CMD ["/start.sh"]
