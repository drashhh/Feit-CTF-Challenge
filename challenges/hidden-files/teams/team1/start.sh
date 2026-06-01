#!/bin/sh
mkdir -p /var/log/nginx /var/log/vsftpd /var/run/vsftpd/empty
exec /usr/bin/supervisord -c /etc/supervisord.conf
