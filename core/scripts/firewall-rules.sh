#!/bin/bash
# FEIT CTF - Firewall Configuration
# Configures UFW and iptables for CTF isolation

set -e

echo "Configuring firewall rules..."

# Reset UFW
ufw --force reset

# Default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH (admin access)
ufw allow 22/tcp comment "Admin SSH"

# Allow OpenVPN
ufw allow 1194/udp comment "OpenVPN"

# Allow noVNC from VPN subnet only
ufw allow from 10.8.0.0/24 to any port 6901:6905 proto tcp comment "noVNC from VPN"

# Allow scoreboard from VPN subnet
ufw allow from 10.8.0.0/24 to any port 5000 proto tcp comment "Scoreboard from VPN"

# Enable UFW
ufw --force enable

echo "UFW configured."

# iptables rules for network isolation
echo "Applying iptables rules..."

# Allow forwarding between VPN and Docker subnets
iptables -I FORWARD -s 10.8.0.0/24 -d 10.10.0.0/16 -j ACCEPT
iptables -I FORWARD -s 10.10.0.0/16 -d 10.8.0.0/24 -j ACCEPT

# Allow forwarding between Docker subnets (cross-team attacks)
iptables -I FORWARD -s 10.10.0.0/16 -d 10.10.0.0/16 -j ACCEPT

# BLOCK internet access from VPN clients
iptables -I FORWARD -s 10.8.0.0/24 ! -d 10.0.0.0/8 -j DROP

# BLOCK internet access from Docker containers
iptables -I FORWARD -s 10.10.0.0/16 ! -d 10.0.0.0/8 -j DROP

# Block Docker containers from accessing host SSH
iptables -I INPUT -s 10.10.0.0/16 -p tcp --dport 22 -j DROP
iptables -I INPUT -s 10.8.0.0/24 -p tcp --dport 22 -j DROP

# Allow established connections
iptables -I FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

echo "iptables rules applied."

# Save iptables rules (persist across reboots)
if command -v netfilter-persistent &> /dev/null; then
    netfilter-persistent save
else
    apt-get install -y iptables-persistent
    netfilter-persistent save
fi

echo ""
echo "Firewall configuration complete."
echo "Summary:"
echo "  - SSH (22): Allowed from all (admin access)"
echo "  - OpenVPN (1194/udp): Allowed from all"
echo "  - noVNC (6901-6905): VPN clients only"
echo "  - Scoreboard (5000): VPN clients only"
echo "  - Internet from VPN/Docker: BLOCKED"
echo "  - Host SSH from VPN/Docker: BLOCKED"
echo "  - Cross-team traffic: ALLOWED (attack surface)"
