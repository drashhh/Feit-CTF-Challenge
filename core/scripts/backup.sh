#!/bin/bash
# FEIT CTF - Backup Script
# Backs up configs, flags, and scoreboard data

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CTF_DIR="${CTF_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
TEMP_DIR="${CTF_DIR}/temp"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="${TEMP_DIR}/backup-${TIMESTAMP}"

mkdir -p "$BACKUP_DIR"

echo "Creating backup: $BACKUP_DIR"

# Backup flags
echo "  - Backing up flags..."
cp -r "${CTF_DIR}/flags" "$BACKUP_DIR/" 2>/dev/null || echo "    (no flags directory)"

# Backup docker config
echo "  - Backing up Docker config..."
cp "${CTF_DIR}/docker/.env" "$BACKUP_DIR/docker-env" 2>/dev/null || echo "    (no .env file)"
cp "${CTF_DIR}/docker/docker-compose.yml" "$BACKUP_DIR/" 2>/dev/null || true

# Backup scoreboard database
echo "  - Backing up scoreboard..."
cp "${CTF_DIR}/docker/scoreboard/data/ctf.db" "$BACKUP_DIR/ctf.db" 2>/dev/null || echo "    (no database)"
cp "${CTF_DIR}/docker/scoreboard/data/submissions.log" "$BACKUP_DIR/submissions.log" 2>/dev/null || echo "    (no log)"

# Backup VPN configs
echo "  - Backing up VPN configs..."
cp -r /etc/openvpn/server "$BACKUP_DIR/openvpn-server/" 2>/dev/null || echo "    (no OpenVPN config)"

# Create tarball
TARBALL="${TEMP_DIR}/ctf-backup-${TIMESTAMP}.tar.gz"
tar czf "$TARBALL" -C "$TEMP_DIR" "backup-${TIMESTAMP}"

# Cleanup uncompressed backup
rm -rf "$BACKUP_DIR"

echo ""
echo "Backup complete: $TARBALL"
echo "Size: $(du -h "$TARBALL" | cut -f1)"
