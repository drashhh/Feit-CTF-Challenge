#!/bin/bash
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE} Deploying FEIT CTF Challenge 3 (Hidden)  ${NC}"
echo -e "${BLUE}==========================================${NC}"

# Check for existing networks that might conflict
for i in {1..5}; do
    if docker network ls | grep -q "ctf-team${i}"; then
        echo -e "${YELLOW}Warning: Network ctf-team${i} from main CTF might conflict. If deployment fails, run 'docker compose down' in the main CTF directory.${NC}"
    fi
done

chmod +x generate_flags.sh
echo -e "\n${YELLOW}[1/4] Generating unique flags...${NC}"
./generate_flags.sh

echo -e "\n${YELLOW}[2/4] Building Docker containers...${NC}"
docker compose build

echo -e "\n${YELLOW}[3/4] Starting Docker containers & Networks...${NC}"
docker compose up -d

echo -e "\n${YELLOW}[4/4] Verifying containers and networking...${NC}"
sleep 3

echo -e "\n${GREEN}Deployment Successful! Access details:${NC}"
echo "-----------------------------------------------------------------"
printf "%-10s %-15s %-15s %-20s\n" "Team" "Container" "IP Address" "Services"
echo "-----------------------------------------------------------------"

for i in {1..5}; do
    CONTAINER="files-team${i}"
    IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CONTAINER 2>/dev/null)
    if [ -z "$IP" ]; then
        IP="Not Running"
    fi
    printf "%-10s %-15s %-15s %-20s\n" "Team $i" "$CONTAINER" "$IP" "FTP (21), Web (80)"
done

echo "-----------------------------------------------------------------"
echo -e "\n${GREEN}Challenge is live! Check README.md for testing instructions.${NC}"
