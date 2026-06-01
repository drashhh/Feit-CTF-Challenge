#!/bin/bash
# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE} Deploying FEIT CTF Web Challenge ${NC}"
echo -e "${BLUE}==========================================${NC}"

# 1. Generate Flags
echo -e "\n${YELLOW}[1/4] Generating unique flags...${NC}"
chmod +x generate_flags.sh
./generate_flags.sh

# 2. Build Containers
echo -e "\n${YELLOW}[2/4] Building Docker containers...${NC}"
docker compose build

# 3. Start Containers
echo -e "\n${YELLOW}[3/4] Starting Docker containers & Networks...${NC}"
docker compose up -d

# 4. Verify & IP Details
echo -e "\n${YELLOW}[4/4] Verifying containers and networking...${NC}"
sleep 3

echo -e "\n${GREEN}Deployment Successful! Access details:${NC}"
echo "--------------------------------------------------"
printf "%-10s %-15s %-15s\n" "Team" "Container" "IP Address"
echo "--------------------------------------------------"

for i in {1..5}; do
    CONTAINER="web-team${i}"
    IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CONTAINER 2>/dev/null)
    if [ -z "$IP" ]; then
        IP="Not Running"
    fi
    printf "%-10s %-15s %-15s\n" "Team $i" "$CONTAINER" "$IP"
done

echo "--------------------------------------------------"
echo -e "\n${GREEN}Challenge is live! Check README.md for testing instructions.${NC}"
