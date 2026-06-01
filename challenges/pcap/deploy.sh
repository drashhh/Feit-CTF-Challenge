#!/bin/bash
# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}  Deploying Challenge 4: Packet Capture Analysis  ${NC}"
echo -e "${BLUE}==================================================${NC}"

# 1. Generate Flags
chmod +x generate_flags.sh
./generate_flags.sh

# 2. Generate PCAPs
# We use a temporary docker container with scapy to ensure it works
echo -e "\n${YELLOW}[1/4] Generating realistic PCAPs with Scapy...${NC}"
docker run --rm -v "$(pwd):/work" -w /work python:3.11-slim sh -c "pip install scapy --quiet && python3 generate_pcaps.py"

if [ $? -ne 0 ]; then
    echo -e "${RED}Error generating PCAPs!${NC}"
    exit 1
fi

# 3. Build Containers
echo -e "\n${YELLOW}[2/4] Building Docker containers...${NC}"
docker compose build

# 4. Start Containers
echo -e "\n${YELLOW}[3/4] Starting Docker containers & Networks...${NC}"
docker compose up -d

# 5. Verify & IP Details
echo -e "\n${YELLOW}[4/4] Verifying services and PCAP availability...${NC}"
sleep 5

echo -e "\n${GREEN}Deployment Successful! Access details:${NC}"
echo "-----------------------------------------------------------------"
printf "%-10s %-15s %-15s %-10s\n" "Team" "Container" "IP Address" "PCAP Size"
echo "-----------------------------------------------------------------"

for i in {1..5}; do
    CONTAINER="pcap-team${i}"
    IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CONTAINER 2>/dev/null)
    if [ -z "$IP" ]; then
        IP="Not Running"
        SIZE="N/A"
    else
        SIZE=$(curl -sI "http://$IP/capture.pcap" | grep -i Content-Length | awk '{print $2}' | tr -d '\r')
        SIZE="${SIZE:-0} bytes"
    fi
    printf "%-10s %-15s %-15s %-10s\n" "Team $i" "$CONTAINER" "$IP" "$SIZE"
done

echo "-----------------------------------------------------------------"
echo -e "\n${GREEN}Challenge is live! Check README.md for analysis steps.${NC}"
