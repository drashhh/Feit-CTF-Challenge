# 6. Operations, Backup, and Reset

## Monitoring During the CTF

### Real-time Monitoring Commands
```bash
# Watch all container status
watch docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Monitor container resource usage
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Watch scoreboard submissions in real-time
tail -f /opt/feit-ctf/scoreboard/data/submissions.log

# Check VPN connected clients
cat /var/log/openvpn/status.log

# Monitor network traffic between teams
tcpdump -i docker0 -n -q
```

### Health Check Script
```bash
#!/bin/bash
# /opt/feit-ctf/scripts/health-check.sh
echo "=== CTF Health Check ==="
echo ""
echo "--- Container Status ---"
docker ps --format "table {{.Names}}\t{{.Status}}" | sort
echo ""
echo "--- VPN Clients ---"
grep "CLIENT_LIST" /var/log/openvpn/status.log 2>/dev/null | wc -l
echo " clients connected"
echo ""
echo "--- Scoreboard ---"
curl -s -o /dev/null -w "HTTP %{http_code}" http://10.10.0.2:5000/
echo ""
echo ""
echo "--- Disk Usage ---"
df -h / | tail -1
echo ""
echo "--- Memory ---"
free -h | head -2
```

## Restarting Broken Services

```bash
# Restart a specific team's challenge
docker restart web-team3

# Restart all containers for a team
docker restart web-team2 sqli-team2 files-team2 pcap-team2 misconfig-team2

# Rebuild a container (if image is corrupted)
cd /opt/feit-ctf
docker compose up -d --force-recreate web-team2

# Restart the scoreboard
docker restart ctf-scoreboard
```

## Handling Cheating Reports

### Detection Methods
1. **Scoreboard logs**: Check submission timestamps and patterns
2. **Container logs**: `docker logs web-team{N}` for suspicious access
3. **Network capture**: `tcpdump -i br-team{N} -w ./temp/capture.pcap`
4. **Cross-reference**: Check if a team submitted another team's self-flag

### Response Actions
1. Review logs in `/opt/feit-ctf/scoreboard/data/submissions.log`
2. Check scoreboard admin panel at `http://10.10.0.2:5000/admin`
3. Invalidate suspicious submissions via admin panel
4. If needed, reset a team's score in the database

## Log Collection

```bash
# Collect all logs to temp directory
mkdir -p ./temp/logs-$(date +%Y%m%d)
LOGDIR="./temp/logs-$(date +%Y%m%d)"

# Container logs
for c in $(docker ps --format '{{.Names}}'); do
    docker logs "$c" > "$LOGDIR/${c}.log" 2>&1
done

# Scoreboard submissions
cp /opt/feit-ctf/scoreboard/data/submissions.log "$LOGDIR/"

# VPN logs
cp /var/log/openvpn/*.log "$LOGDIR/"

# System logs
cp /var/log/auth.log "$LOGDIR/"

tar czf "./temp/ctf-logs-$(date +%Y%m%d).tar.gz" "$LOGDIR"
echo "Logs saved to ./temp/ctf-logs-$(date +%Y%m%d).tar.gz"
```

## Ending the Competition

1. **Announce**: Notify students the CTF is ending (5 min warning)
2. **Freeze scoreboard**: Set `FREEZE=true` in scoreboard config
3. **Screenshot final scores**: Save scoreboard state
4. **Export results**:
   ```bash
   sqlite3 /opt/feit-ctf/scoreboard/data/ctf.db \
     "SELECT team, SUM(points) as score FROM submissions GROUP BY team ORDER BY score DESC;" \
     > ./temp/final-scores.txt
   ```
5. **Collect logs**: Run log collection script above
6. **Stop services**: `docker compose down` (or leave running for review)

## Backup Process

### Pre-event Backup
```bash
#!/bin/bash
# scripts/backup.sh
BACKUP_DIR="./temp/backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup configs
cp -r /opt/feit-ctf/docker "$BACKUP_DIR/"
cp -r /opt/feit-ctf/vpn "$BACKUP_DIR/"
cp -r /opt/feit-ctf/scripts "$BACKUP_DIR/"

# Backup flags
cp /opt/feit-ctf/flags/master-flags.json "$BACKUP_DIR/"

# Backup scoreboard database
cp /opt/feit-ctf/scoreboard/data/ctf.db "$BACKUP_DIR/"

# Backup OpenVPN configs
cp -r /etc/openvpn/server "$BACKUP_DIR/openvpn-server/"

tar czf "./temp/ctf-backup-$(date +%Y%m%d-%H%M%S).tar.gz" "$BACKUP_DIR"
echo "Backup complete: $BACKUP_DIR"
```

### Reset a Team Environment
```bash
#!/bin/bash
# scripts/reset-team.sh <team_number>
TEAM=$1
if [ -z "$TEAM" ]; then echo "Usage: $0 <team_number>"; exit 1; fi

echo "Resetting Team $TEAM..."
docker compose stop web-team${TEAM} sqli-team${TEAM} files-team${TEAM} pcap-team${TEAM} misconfig-team${TEAM}
docker compose rm -f web-team${TEAM} sqli-team${TEAM} files-team${TEAM} pcap-team${TEAM} misconfig-team${TEAM}
docker compose up -d web-team${TEAM} sqli-team${TEAM} files-team${TEAM} pcap-team${TEAM} misconfig-team${TEAM}
echo "Team $TEAM reset complete."
```

### Rebuild Containers
```bash
docker compose build --no-cache
docker compose up -d
```

### Restore Scoreboard
```bash
# Stop scoreboard
docker stop ctf-scoreboard

# Restore database from backup
cp ./temp/backup-XXXXX/ctf.db /opt/feit-ctf/scoreboard/data/ctf.db

# Restart
docker start ctf-scoreboard
```

### Clean Logs After Event
```bash
# Collect final logs first
./scripts/collect-logs.sh

# Clean container logs
docker system prune --volumes -f

# Clean scoreboard data
rm /opt/feit-ctf/scoreboard/data/ctf.db
rm /opt/feit-ctf/scoreboard/data/submissions.log

# Reset for next event
./scripts/generate-flags.sh
./scripts/deploy-challenges.sh
```
