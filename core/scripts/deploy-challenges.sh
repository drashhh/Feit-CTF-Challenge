#!/bin/bash
# FEIT CTF - Deploy/Rebuild Challenge Containers
# Run after generate-flags.sh to deploy with new flags

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CTF_DIR="${CTF_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
DOCKER_DIR="${CTF_DIR}/docker"
TEMP_DIR="${CTF_DIR}/temp"

echo "========================================="
echo " Deploying CTF Challenges"
echo "========================================="

# Check .env exists
if [ ! -f "$DOCKER_DIR/.env" ]; then
    echo "ERROR: $DOCKER_DIR/.env not found. Run generate-flags.sh first."
    exit 1
fi

cd "$DOCKER_DIR"

# Build all images
echo "[1/3] Building Docker images..."
docker compose build --no-cache

# Stop existing containers
echo "[2/3] Stopping existing containers..."
docker compose down --remove-orphans 2>/dev/null || true

# Start everything
echo "[3/3] Starting all containers..."
docker compose up -d

# Wait and check
sleep 5
echo ""
echo "Container status:"
docker compose ps

echo ""
echo "Deployment complete. Verify with:"
echo "  docker compose -f $DOCKER_DIR/docker-compose.yml ps"
echo "  curl http://10.10.0.2:5000 (scoreboard)"
