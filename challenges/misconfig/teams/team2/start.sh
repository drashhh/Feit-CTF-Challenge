#!/bin/bash

# FEIT CTF Misconfigured Service Challenge Startup Script
# This script ensures flags are injected into Redis and Memcached on startup

echo "Starting challenge services..."

# Run the flag injection in the background so it can wait for services to be ready
(
    echo "Waiting for Redis to be ready..."
    until redis-cli -h 127.0.0.1 ping >/dev/null 2>&1; do
        sleep 1
    done
    echo "Injecting Redis flag..."
    redis-cli -h 127.0.0.1 SET flag "$FLAG_REDIS"
    redis-cli -h 127.0.0.1 SET hint "Not everything needs a password. Try GET flag"

    echo "Waiting for Memcached to be ready..."
    until nc -z 127.0.0.1 11211; do
        sleep 1
    done
    echo "Injecting Memcached flag..."
    # Format: set <key> <flags> <exptime> <bytes> [noreply]\r\n<value>\r\n
    echo -e "set secret_flag 0 0 ${#FLAG_MEMCACHED}\r\n${FLAG_MEMCACHED}\r" | nc 127.0.0.1 11211
    echo -e "set hint 0 0 45\r\nNo auth needed. Try: get secret_flag\r" | nc 127.0.0.1 11211
    
    echo "Flags injected successfully."
) &

# Start Supervisor in the foreground
echo "Starting Supervisor..."
exec /usr/bin/supervisord -c /etc/supervisord.conf
