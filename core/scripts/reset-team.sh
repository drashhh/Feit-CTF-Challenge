#!/bin/bash
# FEIT CTF - Reset a single team's environment
# Usage: ./reset-team.sh <team_number>

set -e

TEAM=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CTF_DIR="${CTF_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
DOCKER_DIR="${CTF_DIR}/docker"

if [ -z "$TEAM" ] || [ "$TEAM" -lt 1 ] || [ "$TEAM" -gt 5 ]; then
    echo "Usage: $0 <team_number (1-5)>"
    exit 1
fi

echo "Resetting Team $TEAM environment..."

cd "$DOCKER_DIR"

CONTAINERS="web-team${TEAM} sqli-team${TEAM} files-team${TEAM} pcap-team${TEAM} misconfig-team${TEAM}"

echo "Stopping containers: $CONTAINERS"
docker compose stop $CONTAINERS

echo "Removing containers..."
docker compose rm -f $CONTAINERS

echo "Rebuilding and starting..."
docker compose up -d --force-recreate $CONTAINERS

sleep 3
echo ""
echo "Team $TEAM containers:"
docker compose ps | grep "team${TEAM}"

echo ""
echo "Team $TEAM reset complete."
