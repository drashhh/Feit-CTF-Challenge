#!/bin/bash
# FEIT CTF - Generate .ovpn files for students
# Run as: sudo bash generate-ovpn.sh
# Creates 25 .ovpn files (5 per team)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CTF_DIR="${CTF_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
TEMP_DIR="${CTF_DIR}/temp"
EASYRSA_DIR="/etc/openvpn/easy-rsa"
OUTPUT_DIR="${CTF_DIR}/vpn/clients"
SERVER_IP="192.168.183.123"

TEAMS=5
STUDENTS_PER_TEAM=5

mkdir -p "$OUTPUT_DIR"

cd "$EASYRSA_DIR"

echo "Generating .ovpn files for $((TEAMS * STUDENTS_PER_TEAM)) students..."
echo ""

for TEAM in $(seq 1 $TEAMS); do
    mkdir -p "$OUTPUT_DIR/team${TEAM}"
    for STUDENT in $(seq 1 $STUDENTS_PER_TEAM); do
        CLIENT_NAME="student-team${TEAM}-$(printf '%02d' $STUDENT)"

        # Generate client certificate if it doesn't exist
        if [ ! -f "pki/issued/${CLIENT_NAME}.crt" ]; then
            ./easyrsa build-client-full "$CLIENT_NAME" nopass 2>/dev/null
        fi

        # Create .ovpn file
        cat > "$OUTPUT_DIR/team${TEAM}/${CLIENT_NAME}.ovpn" <<EOF
client
dev tun
proto udp
remote ${SERVER_IP} 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
auth SHA256
verb 3

<ca>
$(cat "${EASYRSA_DIR}/pki/ca.crt")
</ca>

<cert>
$(cat "${EASYRSA_DIR}/pki/issued/${CLIENT_NAME}.crt")
</cert>

<key>
$(cat "${EASYRSA_DIR}/pki/private/${CLIENT_NAME}.key")
</key>

<tls-crypt>
$(cat "${EASYRSA_DIR}/pki/ta.key")
</tls-crypt>
EOF

        echo "  Created: $OUTPUT_DIR/team${TEAM}/${CLIENT_NAME}.ovpn"
    done
done

echo ""
echo "Generated $((TEAMS * STUDENTS_PER_TEAM)) .ovpn files in: $OUTPUT_DIR"
echo ""
echo "Distribution:"
for TEAM in $(seq 1 $TEAMS); do
    echo "  Team $TEAM: $OUTPUT_DIR/team${TEAM}/"
    ls "$OUTPUT_DIR/team${TEAM}/" 2>/dev/null | head -5 | sed 's/^/    /'
done
