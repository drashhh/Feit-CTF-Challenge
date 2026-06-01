#!/bin/bash

# FEIT CTF Linux Command-Line Challenge Deployment Script
# Automates building the environment, generating random hidden flags, and syncing to the scoreboard.

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}   Deploying Linux Command-Line Challenge         ${NC}"
echo -e "${BLUE}==================================================${NC}"

# 1. Build and Start Container
echo -e "\n${YELLOW}[1/4] Building and starting the Linux challenge container...${NC}"
docker compose up -d --build

# Wait for SSH to start
sleep 3

# 2. Generate Random Flags and Hide Them
echo -e "\n${YELLOW}[2/4] Generating random hidden flags for each team...${NC}"

BASE_DIRS=("/opt" "/var/lib" "/var/cache" "/srv" "/tmp" "/home" "/usr/local/src")
SUB_DIRS=("cache" "sessions" "logs" "system" "backups" "config" "tmp" "data")
# Prepare a Python script to update the scoreboard
cat << 'EOF' > sync_linux_scoreboard.py
import sqlite3
import json
import sys
import os

# Read arguments: sys.argv[1] is the JSON payload of flags
flags_payload = json.loads(sys.argv[1])

# Use relative paths based on script location
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
db_path = os.path.join(SCRIPT_DIR, '..', '..', 'core', 'docker', 'scoreboard', 'data', 'ctf.db')
json_path = os.path.join(SCRIPT_DIR, '..', '..', 'core', 'docker', 'scoreboard', 'data', 'flags.json')

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Load existing JSON
with open(json_path, 'r') as f:
    flags_data = json.load(f)

updated_count = 0
for team_id, flag_val in flags_payload.items():
    challenge_name = "linux_fs"
    points = 300
    
    # Check if challenge exists for team
    cursor.execute("SELECT id FROM flags WHERE team_owner = ? AND challenge = ?", (team_id, challenge_name))
    row = cursor.fetchone()
    
    if row:
        cursor.execute("UPDATE flags SET flag_value = ?, points = ? WHERE id = ?", (flag_val, points, row[0]))
    else:
        cursor.execute("INSERT INTO flags (team_owner, challenge, flag_value, points) VALUES (?, ?, ?, ?)", 
                       (team_id, challenge_name, flag_val, points))
    
    updated_count += 1
    
    # Update JSON
    found = False
    for flag_entry in flags_data['flags']:
        if flag_entry['team'] == team_id and flag_entry['challenge'] == challenge_name:
            flag_entry['flag'] = flag_val
            flag_entry['points'] = points
            found = True
            break
            
    if not found:
        flags_data['flags'].append({
            "team": team_id,
            "challenge": challenge_name,
            "flag": flag_val,
            "points": points
        })

conn.commit()
conn.close()

with open(json_path, 'w') as f:
    json.dump(flags_data, f, indent=2)

print(f"Synchronized {updated_count} Linux FS flags into the scoreboard.")
EOF

# Array to store Python payload
JSON_PAYLOAD="{"

> generated_flags_log.txt
echo "--- Generated Flags and Paths ---" > generated_flags_log.txt

DECOYS=("No this is not the fleg" "Try it next time" "Keep digging" "Not here" "Fake flag" "Almost there" "Nothing to see here" "Better luck next time")

TEAMS=("M3" "team2" "team3" "team4" "Demure Hakerz")
USERS=("m3" "korisnik2" "korisnik3" "korisnik4" "demurehakerz")

for i in {1..5}; do
    TEAM="${TEAMS[$((i-1))]}"
    USER="${USERS[$((i-1))]}"
    
    # Generate random flag
    RANDOM_SUFFIX=$(head /dev/urandom | tr -dc A-Z0-9 | head -c 6)
    FLAG="FEIT{team${i}_linux_fs_flag_${RANDOM_SUFFIX}}"
    
    # Base directory is now exclusively the user's home directory
    BASE="/home/$USER"
    
    # We will pick a single target index out of 45 (5 * 3 * 3) for the real flag
    TARGET_INDEX=$(( ( RANDOM % 45 ) + 1 ))
    CURRENT_INDEX=1
    FLAG_LOCATION=""
    
    # Create the 5 top-level random folders
    for f1 in {1..5}; do
        L1_DIR=$(head /dev/urandom | tr -dc a-z0-9 | head -c 8)
        
        # Create 3 subfolders
        for f2 in {1..3}; do
            L2_DIR=$(head /dev/urandom | tr -dc a-z0-9 | head -c 8)
            FULL_PATH="${BASE}/${L1_DIR}/${L2_DIR}"
            
            # Create directories and set base ownership
            docker exec linux-team${i} mkdir -p "$FULL_PATH"
            docker exec linux-team${i} chown -R $USER:$USER "${BASE}/${L1_DIR}"
            docker exec linux-team${i} chmod 700 "${BASE}/${L1_DIR}"
            docker exec linux-team${i} chmod 700 "$FULL_PATH"
            
            # Create 3 encrypted files
            for f3 in {1..3}; do
                FILE_NAME="file_$(head /dev/urandom | tr -dc a-z0-9 | head -c 6).txt"
                FILE_PATH="$FULL_PATH/$FILE_NAME"
                
                if [ $CURRENT_INDEX -eq $TARGET_INDEX ]; then
                    CONTENT="$FLAG"
                    FLAG_LOCATION="$FILE_PATH"
                else
                    CONTENT="${DECOYS[$RANDOM % ${#DECOYS[@]}]}"
                fi
                
                # Encode to HEX
                HEX_CONTENT=$(echo -n "$CONTENT" | xxd -p | tr -d '\n')
                
                docker exec linux-team${i} bash -c "echo '$HEX_CONTENT' > '$FILE_PATH'"
                docker exec linux-team${i} chown $USER:$USER "$FILE_PATH"
                docker exec linux-team${i} chmod 400 "$FILE_PATH"
                
                CURRENT_INDEX=$((CURRENT_INDEX + 1))
            done
        done
    done
    
    echo -e "Team $i Flag: $FLAG"
    echo "$TEAM: $FLAG at $FLAG_LOCATION" >> generated_flags_log.txt
    
    # Build JSON payload
    JSON_PAYLOAD+="\"$TEAM\": \"$FLAG\","
done

# Remove trailing comma and close JSON
JSON_PAYLOAD=${JSON_PAYLOAD%,}
JSON_PAYLOAD+="}"

echo -e "\n${YELLOW}[3/4] Synchronizing flags to the Scoreboard...${NC}"
python3 sync_linux_scoreboard.py "$JSON_PAYLOAD"

echo -e "\n${YELLOW}[4/4] Verifying SSH Access...${NC}"
for i in {1..5}; do
    if nc -z -w 2 10.10.$i.70 22; then 
        echo -e "${GREEN}Team $i SSH Service is UP on 10.10.$i.70:22${NC}"
    else 
        echo -e "${RED}Team $i SSH Service is DOWN or unreachable.${NC}"
    fi
done

echo -e "\n${GREEN}Deployment Complete!${NC}"
echo "Check generated_flags_log.txt for a record of flag locations."
