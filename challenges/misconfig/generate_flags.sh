#!/bin/bash

# Configuration
TEAM_COUNT=5
FLAG_FILE="flags.txt"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Generating unique flags for Misconfigured Service Challenge...${NC}"

# Clear existing flags
> $FLAG_FILE
rm -f teams/team*/flags.env

for i in $(seq 1 $TEAM_COUNT); do
    # Generate random suffixes
    REDIS_RANDOM=$(head /dev/urandom | tr -dc A-Z0-9 | head -c 4)
    MEMCACHED_RANDOM=$(head /dev/urandom | tr -dc A-Z0-9 | head -c 4)
    
    # Construct flags
    REDIS_FLAG="FEIT{team${i}_redis_noauth_flag_${REDIS_RANDOM}}"
    MEMCACHED_FLAG="FEIT{team${i}_memcached_flag_${MEMCACHED_RANDOM}}"
    
    # Save to main flag file
    echo "Team $i Redis: $REDIS_FLAG" >> $FLAG_FILE
    echo "Team $i Memcached: $MEMCACHED_FLAG" >> $FLAG_FILE
    
    # Create team-specific env files for Docker build args
    cat <<EOF > teams/team${i}/flags.env
FLAG_REDIS=$REDIS_FLAG
FLAG_MEMCACHED=$MEMCACHED_FLAG
EOF

    echo -e "${GREEN}Flags generated for Team $i${NC}"
done

echo -e "\n${BLUE}All flags saved to $FLAG_FILE and team env files.${NC}"
chmod +x teams/team*/flags.env 2>/dev/null || true
