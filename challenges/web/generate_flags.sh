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
    
    # Generate random 4-character hex strings
    RAND_HTML=$(openssl rand -hex 2 | tr 'a-z' 'A-Z')
    RAND_HEADER=$(openssl rand -hex 2 | tr 'a-z' 'A-Z')
    
    HTML_FLAG="FEIT{team${i}_web_source_flag_${RAND_HTML}}"
    HEADER_FLAG="FEIT{team${i}_http_header_flag_${RAND_HEADER}}"
    
    # Insert or update HTML flag in index.html
    if grep -q "HTML_FLAG_PLACEHOLDER" "$TEAM_DIR/index.html"; then
        sed -i "s/<!-- HTML_FLAG_PLACEHOLDER -->/<!-- Debug: ${HTML_FLAG} -->/g" "$TEAM_DIR/index.html"
    else
        sed -i -E "s/<!-- Debug: FEIT\{team${i}_web_source_flag_[A-Z0-9]{4}\} -->/<!-- Debug: ${HTML_FLAG} -->/g" "$TEAM_DIR/index.html"
    fi
    
    # Insert or update Header flag in nginx.conf
    if grep -q "HEADER_FLAG_PLACEHOLDER" "$TEAM_DIR/nginx.conf"; then
        sed -i "s/HEADER_FLAG_PLACEHOLDER/${HEADER_FLAG}/g" "$TEAM_DIR/nginx.conf"
    else
        sed -i -E "s/X-Secret-Flag \"FEIT\{team${i}_http_header_flag_[A-Z0-9]{4}\}\"/X-Secret-Flag \"${HEADER_FLAG}\"/g" "$TEAM_DIR/nginx.conf"
    fi
    
    echo -e "${GREEN}Team $i Flags Generated:${NC}"
    echo "  HTML:   $HTML_FLAG"
    echo "  Header: $HEADER_FLAG"
done

echo -e "${BLUE}Flag generation complete!${NC}"
