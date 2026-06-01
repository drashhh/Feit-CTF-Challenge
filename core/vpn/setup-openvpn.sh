#!/bin/bash
# FEIT CTF - OpenVPN Server Setup
# Run as: sudo bash setup-openvpn.sh

set -e

echo "Setting up OpenVPN server..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CTF_DIR="${CTF_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
TEMP_DIR="${CTF_DIR}/temp"
EASYRSA_DIR="/etc/openvpn/easy-rsa"
SERVER_DIR="/etc/openvpn/server"

# Server's external IP (change if needed)
SERVER_IP="192.168.183.123"
VPN_SUBNET="10.8.0.0"
VPN_MASK="255.255.255.0"

# Install if needed
apt-get install -y openvpn easy-rsa

# Setup Easy-RSA
mkdir -p "$EASYRSA_DIR"
cp -r /usr/share/easy-rsa/* "$EASYRSA_DIR/" 2>/dev/null || true

cd "$EASYRSA_DIR"

# Initialize PKI
if [ ! -d "pki" ]; then
    ./easyrsa init-pki
    echo "FEIT-CTF-CA" | ./easyrsa build-ca nopass
    ./easyrsa gen-dh
    ./easyrsa build-server-full server nopass
    openvpn --genkey secret "${EASYRSA_DIR}/pki/ta.key"
fi

# Create server config
mkdir -p "$SERVER_DIR"
cat > "$SERVER_DIR/server.conf" <<EOF
port 1194
proto udp
dev tun

ca ${EASYRSA_DIR}/pki/ca.crt
cert ${EASYRSA_DIR}/pki/issued/server.crt
key ${EASYRSA_DIR}/pki/private/server.key
dh ${EASYRSA_DIR}/pki/dh.pem
tls-crypt ${EASYRSA_DIR}/pki/ta.key

server ${VPN_SUBNET} ${VPN_MASK}
ifconfig-pool-persist /var/log/openvpn/ipp.txt

# Push routes to team networks
push "route 10.10.0.0 255.255.0.0"

# Prevent client-to-client direct communication (force through server)
client-to-client

keepalive 10 120
cipher AES-256-GCM
auth SHA256

user nobody
group nogroup
persist-key
persist-tun

status /var/log/openvpn/status.log
log-append /var/log/openvpn/openvpn.log
verb 3

# Prevent DNS leaks - no DNS pushed
# Students don't need DNS in the lab
EOF

# Create log directory
mkdir -p /var/log/openvpn

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-openvpn.conf
sysctl -p /etc/sysctl.d/99-openvpn.conf

# Enable and start OpenVPN
systemctl enable openvpn-server@server
systemctl restart openvpn-server@server

echo ""
echo "OpenVPN server setup complete!"
echo "  Server IP: $SERVER_IP"
echo "  VPN subnet: $VPN_SUBNET/24"
echo "  Config: $SERVER_DIR/server.conf"
echo ""
echo "Next: Generate student .ovpn files with:"
echo "  sudo bash ${CTF_DIR}/vpn/generate-ovpn.sh"
