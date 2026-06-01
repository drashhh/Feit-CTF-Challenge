FROM alpine:3.18

# Install dependencies
RUN apk add --no-cache \
    redis \
    memcached \
    nginx \
    supervisor \
    bash \
    curl

# Create necessary directories
RUN mkdir -p /run/nginx /run/redis /run/supervisord /var/www/localhost/htdocs

# Arguments for flags
ARG FLAG_REDIS="FEIT{default_redis_flag}"
ARG FLAG_MEMCACHED="FEIT{default_memcached_flag}"

# Environment variables
ENV FLAG_REDIS=${FLAG_REDIS}
ENV FLAG_MEMCACHED=${FLAG_MEMCACHED}

# Copy configurations
COPY redis.conf /etc/redis.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisord.conf
COPY start.sh /usr/local/bin/start.sh
COPY website/ /var/www/localhost/htdocs/

# Set permissions
RUN chmod +x /usr/local/bin/start.sh && \
    chown -R nginx:nginx /var/www/localhost/htdocs

# Expose ports
EXPOSE 80 6379 11211

# Start services via supervisor
CMD ["/usr/local/bin/start.sh"]
