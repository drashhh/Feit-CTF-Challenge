#!/bin/bash
# FEIT CTF - Flag Generator
# Generates unique flags for all teams and challenges
# Output: /opt/feit-ctf/flags/master-flags.json and .env file for docker-compose

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CTF_DIR="${CTF_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
OUTPUT_DIR="${CTF_DIR}/flags"
DOCKER_DIR="${CTF_DIR}/docker"
TEMP_DIR="${CTF_DIR}/temp"

mkdir -p "$OUTPUT_DIR" "$TEMP_DIR"

TEAMS=5

declare -a CHALLENGE_NAMES=(
    "web_source"
    "web_header"
    "sqli_database"
    "hidden_ftp"
    "hidden_web"
    "hidden_web_hmac"
    "hidden_web_des"
    "pcap_http"
    "pcap_dns"
    "redis_noauth"
    "memcached"
)

declare -A CHALLENGE_POINTS=(
    ["web_source"]="100"
    ["web_header"]="100"
    ["sqli_database"]="200"
    ["hidden_ftp"]="150"
    ["hidden_web"]="150"
    ["hidden_web_hmac"]="175"
    ["hidden_web_des"]="100"
    ["pcap_http"]="200"
    ["pcap_dns"]="200"
    ["redis_noauth"]="250"
    ["memcached"]="250"
)

echo "Generating flags for $TEAMS teams..."

# Start JSON file
echo '{' > "$OUTPUT_DIR/master-flags.json"
echo '  "generated_at": "'$(date -Iseconds)'",' >> "$OUTPUT_DIR/master-flags.json"
echo '  "flags": [' >> "$OUTPUT_DIR/master-flags.json"

# Start .env file
echo "# FEIT CTF - Generated Flags" > "$DOCKER_DIR/.env"
echo "# Generated at: $(date)" >> "$DOCKER_DIR/.env"
echo "" >> "$DOCKER_DIR/.env"

# Scoreboard secret
echo "SCOREBOARD_SECRET_KEY=$(openssl rand -hex 32)" >> "$DOCKER_DIR/.env"
echo "ADMIN_PASSWORD=$(openssl rand -base64 12)" >> "$DOCKER_DIR/.env"
echo "" >> "$DOCKER_DIR/.env"

FIRST=true
for TEAM_NUM in $(seq 1 $TEAMS); do
    echo "  Team $TEAM_NUM:"

    # VNC password
    VNC_PASS=$(openssl rand -base64 8 | tr -d '=+/')
    echo "TEAM${TEAM_NUM}_VNC_PASS=${VNC_PASS}" >> "$DOCKER_DIR/.env"

    for CHALLENGE in "${CHALLENGE_NAMES[@]}"; do
        RANDOM_SUFFIX=$(openssl rand -hex 4)
        FLAG="FEIT{team${TEAM_NUM}_${CHALLENGE}_flag_${RANDOM_SUFFIX}}"
        ENV_VALUE="$FLAG"

        if [[ "$CHALLENGE" == "hidden_ftp" ]] || [[ "$CHALLENGE" == "hidden_web" ]]; then
            # Keep the normal FLAG but encode it in Hex
            ENV_VALUE=$(echo -n "$FLAG" | xxd -p -c 256 | tr -d '\n')
        fi

        POINTS=${CHALLENGE_POINTS[$CHALLENGE]}

        # JSON entry
        if [ "$FIRST" = true ]; then
            FIRST=false
        else
            echo "," >> "$OUTPUT_DIR/master-flags.json"
        fi
        printf '    {"team": "team%d", "challenge": "%s", "flag": "%s", "points": %s}' \
            "$TEAM_NUM" "$CHALLENGE" "$FLAG" "$POINTS" >> "$OUTPUT_DIR/master-flags.json"

        # .env entry - map to docker-compose variable names
        TEAM_UPPER="TEAM${TEAM_NUM}"
        CHALLENGE_UPPER=$(echo "$CHALLENGE" | tr '[:lower:]' '[:upper:]')

        case "$CHALLENGE" in
            web_source)   echo "${TEAM_UPPER}_WEB_SOURCE_FLAG=${ENV_VALUE}" >> "$DOCKER_DIR/.env" ;;
            web_header)   echo "${TEAM_UPPER}_WEB_HEADER_FLAG=${ENV_VALUE}" >> "$DOCKER_DIR/.env" ;;
            sqli_database) echo "${TEAM_UPPER}_SQLI_FLAG=${ENV_VALUE}" >> "$DOCKER_DIR/.env" ;;
            hidden_ftp)   echo "${TEAM_UPPER}_HIDDEN_FTP_FLAG=${ENV_VALUE}" >> "$DOCKER_DIR/.env" ;;
            hidden_web)   echo "${TEAM_UPPER}_HIDDEN_WEB_FLAG=${ENV_VALUE}" >> "$DOCKER_DIR/.env" ;;
            hidden_web_hmac) echo "${TEAM_UPPER}_HIDDEN_WEB_HMAC_FLAG=${ENV_VALUE}" >> "$DOCKER_DIR/.env" ;;
            pcap_http)    echo "${TEAM_UPPER}_PCAP_HTTP_FLAG=${ENV_VALUE}" >> "$DOCKER_DIR/.env" ;;
            pcap_dns)     echo "${TEAM_UPPER}_PCAP_DNS_FLAG=${ENV_VALUE}" >> "$DOCKER_DIR/.env" ;;
            redis_noauth) echo "${TEAM_UPPER}_REDIS_FLAG=${ENV_VALUE}" >> "$DOCKER_DIR/.env" ;;
            memcached)    echo "${TEAM_UPPER}_MEMCACHED_FLAG=${ENV_VALUE}" >> "$DOCKER_DIR/.env" ;;
        esac

        echo "    $CHALLENGE: $FLAG ($POINTS pts)"
    done
    echo "" >> "$DOCKER_DIR/.env"
done

# Close JSON
echo "" >> "$OUTPUT_DIR/master-flags.json"
echo "  ]" >> "$OUTPUT_DIR/master-flags.json"
echo "}" >> "$OUTPUT_DIR/master-flags.json"

# Also copy flags JSON to scoreboard data dir for loading
mkdir -p "$DOCKER_DIR/scoreboard/data"
cp "$OUTPUT_DIR/master-flags.json" "$DOCKER_DIR/scoreboard/data/flags.json"

# Secure the master flags file
chmod 600 "$OUTPUT_DIR/master-flags.json"
chmod 600 "$DOCKER_DIR/.env"

echo ""
echo "Done! Generated $(echo ${#CHALLENGE_NAMES[@]} '*' $TEAMS | bc) flags."
echo "Master flags: $OUTPUT_DIR/master-flags.json"
echo "Docker env:   $DOCKER_DIR/.env"
