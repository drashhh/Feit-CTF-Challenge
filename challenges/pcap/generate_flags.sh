#!/bin/bash
# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Generating unique flags for all teams...${NC}"

# Clear previous flags
> flags.env

for i in {1..5}; do
    RAND_HTTP=$(openssl rand -hex 2 | tr 'a-z' 'A-Z')
    RAND_DNS=$(openssl rand -hex 2 | tr 'a-z' 'A-Z')
    
    HTTP_FLAG="FEIT{team${i}_pcap_http_flag_${RAND_HTTP}}"
    DNS_FLAG="FEIT{team${i}_pcap_dns_flag_${RAND_DNS}}"
    
    echo "TEAM${i}_HTTP_FLAG=${HTTP_FLAG}" >> flags.env
    echo "TEAM${i}_DNS_FLAG=${DNS_FLAG}" >> flags.env
    
    echo -e "${GREEN}Team $i Flags Generated:${NC}"
    echo "  HTTP: $HTTP_FLAG"
    echo "  DNS:  $DNS_FLAG"
done

echo -e "${BLUE}Flag generation complete!${NC}"
