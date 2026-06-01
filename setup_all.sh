#!/bin/bash
# ==============================================================================
# FEIT CTF - Master Setup & Deployment Script
# ==============================================================================
# This script automates the entire setup of the FEIT CTF environment:
# 1. System dependencies & Docker installation
# 2. Network configuration & IP Forwarding
# 3. OpenVPN Server Setup
# 4. Challenge deployment (Docker Compose)
# 5. Flag generation & Scoreboard setup
# 6. Firewall rules (UFW/iptables)
# ==============================================================================

set -e

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Configuration ---
BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/feit_ctf_setup.log"

# --- Functions ---
log() { echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"; exit 1; }

check_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        error "This script must be run as root. Please use sudo."
    fi
}

install_dependencies() {
    log "Updating system and installing base dependencies..."
    apt-get update -qq
    apt-get install -y -qq \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        ufw \
        jq \
        openssl \
        net-tools \
        git \
        iptables-persistent \
        python3-pip \
        xxd

    # Docker Installation
    if ! command -v docker &> /dev/null; then
        log "Installing Docker..."
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
        apt-get update -qq
        apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin
        systemctl enable docker
        systemctl start docker
    else
        success "Docker already installed."
    fi
}

setup_network() {
    log "Configuring network and IP forwarding..."
    echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-feit-ctf.conf
    sysctl -p /etc/sysctl.d/99-feit-ctf.conf
}

setup_openvpn() {
    log "Setting up OpenVPN server..."
    if [[ -f "$BUNDLE_DIR/core/vpn/setup-openvpn.sh" ]]; then
        export CTF_DIR="$BUNDLE_DIR/core"
        bash "$BUNDLE_DIR/core/vpn/setup-openvpn.sh"
    else
        warn "OpenVPN setup script not found in bundle. Manual setup required."
    fi
}

deploy_challenges() {
    log "Deploying CTF challenges..."
    
    # 1. Generate Flags
    if [[ -f "$BUNDLE_DIR/core/scripts/generate-flags.sh" ]]; then
        log "Generating master flags..."
        export CTF_DIR="$BUNDLE_DIR/core"
        bash "$BUNDLE_DIR/core/scripts/generate-flags.sh"
    fi

    # 2. Deploy main CTF Docker services
    log "Starting main CTF containers (Scoreboard, Kali, etc.)..."
    cd "$BUNDLE_DIR/core/docker"
    docker compose build
    docker compose up -d

    # 3. Deploy specific sub-challenges
    CHALLENGES=(
        "challenges/web"
        "challenges/linux"
        "challenges/pcap"
        "challenges/misconfig"
        "challenges/hidden-files"
        "challenges/brute-force"
        "challenges/db-exploit"
        "challenges/zip-crack"
        "challenges/linux-fs"
    )

    for CHALLENGE in "${CHALLENGES[@]}"; do
        if [[ -d "$BUNDLE_DIR/$CHALLENGE" ]]; then
            log "Deploying $CHALLENGE..."
            cd "$BUNDLE_DIR/$CHALLENGE"
            if [[ -f "./deploy.sh" ]]; then
                chmod +x ./deploy.sh
                ./deploy.sh
            else
                docker compose up -d
            fi
        fi
    done
}

configure_firewall() {
    log "Applying firewall rules..."
    if [[ -f "$BUNDLE_DIR/CTF/scripts/firewall-rules.sh" ]]; then
        bash "$BUNDLE_DIR/CTF/scripts/firewall-rules.sh"
    else
        warn "Firewall rules script not found in bundle."
    fi
}

# --- Main ---
main() {
    echo -e "${BLUE}======================================================${NC}"
    echo -e "${BLUE}    FEIT CTF Master Setup Started                     ${NC}"
    echo -e "${BLUE}======================================================${NC}"

    check_root
    install_dependencies
    setup_network
    setup_openvpn
    deploy_challenges
    configure_firewall

    echo -e "\n${GREEN}======================================================${NC}"
    echo -e "${GREEN}    Setup Complete!                                   ${NC}"
    echo -e "${GREEN}======================================================${NC}"
    log "Detailed log: $LOG_FILE"
    echo ""
    echo "Next Steps:"
    echo "1. Distribute .ovpn files from: /etc/openvpn/client/ (or wherever your vpn script puts them)"
    echo "2. Access scoreboard at: http://10.10.0.2:5000"
    echo "3. Review admin docs in: $BUNDLE_DIR/CTF/docs/"
}

main "$@"
