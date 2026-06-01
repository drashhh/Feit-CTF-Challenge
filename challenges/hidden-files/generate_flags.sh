#!/bin/bash
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Generating unique flags for all teams...${NC}"

for i in {1..5}; do
    TEAM_DIR="teams/team${i}"
    
    if [ ! -d "$TEAM_DIR" ]; then
        echo "Error: Directory $TEAM_DIR not found!"
        continue
    fi
    
    RAND_FTP=$(openssl rand -hex 2 | tr 'a-z' 'A-Z')
    RAND_WEB=$(openssl rand -hex 2 | tr 'a-z' 'A-Z')
    
    FTP_FLAG="FEIT{team${i}_hidden_ftp_flag_${RAND_FTP}}"
    WEB_FLAG="FEIT{team${i}_hidden_web_flag_${RAND_WEB}}"
    
    echo "$FTP_FLAG" > "$TEAM_DIR/ftp/.backup/admin_notes.txt"
    echo "$WEB_FLAG" > "$TEAM_DIR/website/secret/flag.txt"
    
    echo -e "${GREEN}Team $i Flags Generated:${NC}"
    echo "  FTP: $FTP_FLAG"
    echo "  Web: $WEB_FLAG"
done

echo -e "${BLUE}Flag generation complete!${NC}"
