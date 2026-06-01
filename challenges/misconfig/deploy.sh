#!/bin/bash

# FEIT CTF Misconfigured Service Challenge Deployment Script
# This script builds and starts the challenge containers for all teams.

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}   Deploying Misconfigured Service Challenge      ${NC}"
echo -e "${BLUE}==================================================${NC}"

# 1. Generate Flags
echo -e "\n${YELLOW}[1/4] Generating unique flags...${NC}"
chmod +x generate_flags.sh
./generate_flags.sh

# Load flags into environment for docker-compose
for i in {1..5}; do
    if [ -f "teams/team$i/flags.env" ]; then
        export FLAG_REDIS_$i=$(grep FLAG_REDIS teams/team$i/flags.env | cut -d= -f2)
        export FLAG_MEMCACHED_$i=$(grep FLAG_MEMCACHED teams/team$i/flags.env | cut -d= -f2)
    fi
done

# 2. Ensure Networks Exist
echo -e "\n${YELLOW}[2/4] Verifying Docker networks...${NC}"
for i in {1..5}; do
    NETWORK_NAME="docker_ctf-team$i"
    if ! docker network ls | grep -q "$NETWORK_NAME"; then
        echo -e "Creating network $NETWORK_NAME..."
        docker network create --subnet=10.10.$i.0/24 $NETWORK_NAME
    else
        echo -e "Network $NETWORK_NAME already exists."
    fi
done

# 3. Build and Start Containers
echo -e "\n${YELLOW}[3/4] Building and starting containers...${NC}"
# Use --build to ensure fresh flags are injected
docker compose up -d --build

# 4. Verify Health
echo -e "\n${YELLOW}[4/4] Verifying services...${NC}"
sleep 5

echo -e "\n${GREEN}Deployment Summary:${NC}"
echo "-------------------------------------------------------------------------------"
printf "%-10s %-15s %-15s %-10s %-10s %-10s\n" "Team" "Container" "IP Address" "HTTP" "Redis" "Memcached"
echo "-------------------------------------------------------------------------------"

for i in {1..5}; do
    CONTAINER="misconfig-team$i"
    IP="10.10.$i.60"
    
    # Check HTTP
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 http://$IP)
    if [ "$HTTP_STATUS" == "200" ]; then HTTP_ICON="${GREEN}OK${NC}"; else HTTP_ICON="${RED}FAIL${NC}"; fi
    
    # Check Redis (using nc to check port)
    if nc -z -w 2 $IP 6379; then REDIS_ICON="${GREEN}OK${NC}"; else REDIS_ICON="${RED}FAIL${NC}"; fi
    
    # Check Memcached
    if nc -z -w 2 $IP 11211; then MEMCACHED_ICON="${GREEN}OK${NC}"; else MEMCACHED_ICON="${RED}FAIL${NC}"; fi
    
    printf "%-10s %-15s %-15s %-19s %-19s %-19s\n" "Team $i" "$CONTAINER" "$IP" "$HTTP_ICON" "$REDIS_ICON" "$MEMCACHED_ICON"
done

echo "-------------------------------------------------------------------------------"
echo -e "\n${GREEN}Challenge is live! Access IP: 10.10.N.60${NC}"
echo -e "Refer to README.md for solution steps."
