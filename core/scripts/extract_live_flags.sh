#!/bin/bash

echo "Extracting live Web Flags..."
for i in {1..5}; do
  SRC_FLAG=$(docker exec web-team$i grep -o 'FEIT{[^}]*}' /usr/share/nginx/html/index.html | head -n 1)
  HDR_FLAG=$(docker exec web-team$i grep -o 'FEIT{[^}]*}' /etc/nginx/conf.d/default.conf 2>/dev/null || docker exec web-team$i grep -o 'FEIT{[^}]*}' /etc/nginx/nginx.conf 2>/dev/null | head -n 1)
  echo "TEAM${i}_WEB_SOURCE=$SRC_FLAG"
  echo "TEAM${i}_WEB_HEADER=$HDR_FLAG"
done

echo "Extracting live SQLi Flags..."
for i in {1..5}; do
  SQL_FLAG=$(docker exec sqli-team$i env | grep FLAG= | cut -d= -f2)
  if [ -z "$SQL_FLAG" ]; then
    SQL_FLAG=$(docker exec sqli-team$i cat /docker-entrypoint-initdb.d/init.sql 2>/dev/null | grep -o 'FEIT{[^}]*}')
  fi
  echo "TEAM${i}_SQLI=$SQL_FLAG"
done

echo "Extracting live Hidden Files Flags..."
for i in {1..5}; do
  FTP_FLAG=$(docker exec files-team$i cat /var/ftp/pub/.hidden_flag.txt 2>/dev/null)
  WEB_FLAG=$(docker exec files-team$i cat /usr/share/nginx/html/.secret_flag.txt 2>/dev/null)
  WEB_HMAC_FLAG=$(docker exec files-team$i cat /usr/share/nginx/html/admin/.hmac_flag.txt 2>/dev/null)
  
  echo "TEAM${i}_HIDDEN_FTP=$FTP_FLAG"
  echo "TEAM${i}_HIDDEN_WEB=$WEB_FLAG"
  echo "TEAM${i}_HIDDEN_WEB_HMAC=$WEB_HMAC_FLAG"
done

echo "Extracting live PCAP Flags..."
for i in {1..5}; do
  HTTP_FLAG=$(docker exec pcap-team$i env | grep FLAG_HTTP | cut -d= -f2)
  DNS_FLAG=$(docker exec pcap-team$i env | grep FLAG_DNS | cut -d= -f2)
  echo "TEAM${i}_PCAP_HTTP=$HTTP_FLAG"
  echo "TEAM${i}_PCAP_DNS=$DNS_FLAG"
done

echo "Extracting live Misconfig Flags..."
for i in {1..5}; do
  REDIS_FLAG=$(docker exec misconfig-team$i env | grep FLAG_REDIS | cut -d= -f2)
  MEM_FLAG=$(docker exec misconfig-team$i env | grep FLAG_MEMCACHED | cut -d= -f2)
  echo "TEAM${i}_REDIS=$REDIS_FLAG"
  echo "TEAM${i}_MEMCACHED=$MEM_FLAG"
done
