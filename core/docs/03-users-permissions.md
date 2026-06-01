# 3. User and Permission Model

## Host Users

### Admin User: joker
- Full sudo access
- SSH access via key authentication
- Manages all CTF infrastructure
- Only user that can access Docker daemon
- Access: `ssh joker@192.168.183.123`

### Team Users (host level)
Not created on the host directly. Team access is through:
1. VPN connection (per-student .ovpn file)
2. VNC desktop (per-team, accessed via browser through VPN)
3. Scoreboard web login (per-team credentials)

## VPN Access

Each student receives a unique .ovpn file:
- `student-team1-01.ovpn` through `student-team1-05.ovpn`
- `student-team2-01.ovpn` through `student-team2-05.ovpn`
- etc.

The .ovpn files contain embedded certificates — no password needed to connect.
Revoking access = revoking the certificate.

## VNC Desktop Access

Each team shares one VNC desktop container:

| Team   | VNC URL (via VPN)              | Password Placeholder |
|--------|--------------------------------|----------------------|
| Team 1 | http://10.10.0.1:6901          | <TEAM1_VNC_PASS>     |
| Team 2 | http://10.10.0.1:6902          | <TEAM2_VNC_PASS>     |
| Team 3 | http://10.10.0.1:6903          | <TEAM3_VNC_PASS>     |
| Team 4 | http://10.10.0.1:6904          | <TEAM4_VNC_PASS>     |
| Team 5 | http://10.10.0.1:6905          | <TEAM5_VNC_PASS>     |

Inside VNC containers:
- User: `student` (UID 1000)
- No sudo
- Pre-installed security tools
- Home directory: `/home/student`

## Scoreboard Login

| Team   | Username | Password Placeholder |
|--------|----------|----------------------|
| Team 1 | team1    | <TEAM1_PASSWORD>     |
| Team 2 | team2    | <TEAM2_PASSWORD>     |
| Team 3 | team3    | <TEAM3_PASSWORD>     |
| Team 4 | team4    | <TEAM4_PASSWORD>     |
| Team 5 | team5    | <TEAM5_PASSWORD>     |
| Admin  | admin    | <ADMIN_PASSWORD>     |

## File Permissions for Flags and Services

### Flag Files
- Owner: root
- Permissions: 0444 (read-only for all)
- Stored inside containers at predictable locations
- Students cannot modify flags inside their own containers because:
  - Container user is non-root
  - Flag files owned by root with no write permission
  - Where possible, containers use read-only filesystem (`read_only: true`)

### Service Files
- Application code: owned by `www-data` or service user
- Config files: owned by root, readable by service user
- Log files: writable by service user only
- Database files: owned by mysql/redis user

### Preventing Flag Tampering
1. Containers restart automatically (`restart: unless-stopped`)
2. Flag files are baked into images (not mounted volumes)
3. A flag-checker cron on host verifies flags every 60 seconds
4. If a flag is missing/changed, the container is auto-restarted
5. Admin can manually reset: `./scripts/reset-team.sh <team_number>`

## SSH Hardening

```
# /etc/ssh/sshd_config additions
PermitRootLogin no
AllowUsers joker
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
```

Only `joker` can SSH to the host. Students have no SSH access to the host machine.
