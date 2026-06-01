# 8. Admin Checklist

## Pre-Event (Day Before)

- [ ] Server 192.168.183.123 is accessible via SSH as `joker`
- [ ] Ubuntu 22.04 is up to date (`sudo apt update && sudo apt upgrade`)
- [ ] Docker and Docker Compose are installed and working
- [ ] OpenVPN server is configured and running
- [ ] Generated .ovpn files for all students (25 files, 5 per team)
- [ ] Test VPN connection from an external machine
- [ ] Run `./scripts/generate-flags.sh` to create fresh flags
- [ ] Run `./scripts/deploy-challenges.sh` to build and start all containers
- [ ] Verify all containers are running: `docker ps`
- [ ] Test each challenge type manually (can you find the flags?)
- [ ] Scoreboard is accessible at http://10.10.0.2:5000
- [ ] Test scoreboard login for each team
- [ ] Test flag submission on scoreboard
- [ ] VNC desktops are accessible for all 5 teams
- [ ] Firewall rules are applied (`./scripts/firewall-rules.sh`)
- [ ] Verify: students CANNOT access the internet from VPN/containers
- [ ] Verify: students CANNOT SSH to the host
- [ ] Verify: teams CAN reach other teams' challenge containers
- [ ] Run `./scripts/backup.sh` to create a pre-event backup
- [ ] Print/distribute student instructions document
- [ ] Prepare team credentials sheet (VNC passwords, scoreboard logins)

## Event Day - Setup (1 hour before)

- [ ] SSH to server, run health check: `./scripts/health-check.sh`
- [ ] Restart all containers fresh: `docker compose restart`
- [ ] Clear any test submissions from scoreboard
- [ ] Verify OpenVPN is accepting connections
- [ ] Open monitoring terminals:
  - `watch docker ps`
  - `tail -f /opt/feit-ctf/scoreboard/data/submissions.log`
- [ ] Distribute .ovpn files to students
- [ ] Distribute VNC passwords to teams
- [ ] Distribute scoreboard login credentials
- [ ] Brief students on rules and format

## During the Event

- [ ] Monitor container health every 15 minutes
- [ ] Watch scoreboard for unusual submission patterns
- [ ] Restart any crashed containers immediately
- [ ] Be available for technical support (not hints!)
- [ ] Run flag integrity check: `./scripts/check-flags.sh`
- [ ] Take periodic scoreboard screenshots

## Event End

- [ ] Give 5-minute warning to students
- [ ] Freeze the scoreboard
- [ ] Export final scores
- [ ] Collect all logs: `./scripts/collect-logs.sh`
- [ ] Screenshot final scoreboard
- [ ] Announce winners
- [ ] Have students disconnect VPN
- [ ] Revoke all VPN certificates (optional, for security)

## Post-Event

- [ ] Run full backup: `./scripts/backup.sh`
- [ ] Stop all containers: `docker compose down`
- [ ] Review logs for any security incidents
- [ ] Prepare summary/report for faculty
- [ ] Archive the backup
- [ ] Clean up if not needed: `docker system prune --volumes -f`
