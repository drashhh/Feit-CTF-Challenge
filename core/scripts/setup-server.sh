#!/bin/bash
# FEIT CTF - Master Server Setup Script
# Run as: sudo bash setup-server.sh
# Server: 192.168.183.123 (Ubuntu 22.04)

set -e

echo "========================================="
echo " FEIT CTF - Server Setup"
echo " Target: 192.168.183.123"
echo "========================================="

# Check if running as root/sudo
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run with sudo"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CTF_DIR="${CTF_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
TEMP_DIR="${CTF_DIR}/temp"

# 1. Update system
echo "[1/8] Updating system..."
apt-get update
apt-get upgrade -y
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    ufw \
    jq \
    openssl \
    net-tools

# 2. Install Docker
echo "[2/8] Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl enable docker
    systemctl start docker
    usermod -aG docker joker
else
    echo "  Docker already installed."
fi

# 3. Install OpenVPN
echo "[3/8] Installing OpenVPN..."
apt-get install -y openvpn easy-rsa

# 4. Create CTF directory structure
echo "[4/8] Creating directory structure..."
mkdir -p "${CTF_DIR}"/{docker,vpn,scripts,flags,temp}
mkdir -p "${CTF_DIR}/docker/scoreboard/data"

# 5. Copy project files (assumes files are in current directory)
echo "[5/8] Copying project files..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -d "${SCRIPT_DIR}/docker" ]; then
    cp -r "${SCRIPT_DIR}/docker/"* "${CTF_DIR}/docker/"
    cp -r "${SCRIPT_DIR}/scripts/"* "${CTF_DIR}/scripts/"
    cp -r "${SCRIPT_DIR}/vpn/"* "${CTF_DIR}/vpn/"
    chmod +x "${CTF_DIR}/scripts/"*.sh
    chmod +x "${CTF_DIR}/vpn/"*.sh
fi

# 6. Configure firewall
echo "[6/8] Configuring firewall..."
bash "${CTF_DIR}/scripts/firewall-rules.sh"

# 7. Generate flags
echo "[7/8] Generating flags..."
bash "${CTF_DIR}/scripts/generate-flags.sh"

# 8. Build and start containers
echo "[8/8] Building and starting Docker containers..."
cd "${CTF_DIR}/docker"
docker compose build
docker compose up -d

echo ""
echo "========================================="
echo " Setup Complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "  1. Configure OpenVPN: sudo bash ${CTF_DIR}/vpn/setup-openvpn.sh"
echo "  2. Generate student .ovpn files: sudo bash ${CTF_DIR}/vpn/generate-ovpn.sh"
echo "  3. Check containers: docker compose -f ${CTF_DIR}/docker/docker-compose.yml ps"
echo "  4. Access scoreboard: http://10.10.0.2:5000"
echo "  5. Review admin checklist: ${CTF_DIR}/docs/08-admin-checklist.md"
echo ""
echo "Temp directory: ${TEMP_DIR}"
