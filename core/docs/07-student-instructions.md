# FEIT CTF - Student Instructions

## Welcome to the FEIT Capture The Flag Competition!

You are participating in an attack/defense CTF exercise. Your team will defend your own services while trying to find flags hidden in other teams' vulnerable services.

## Getting Connected

### Step 1: Install OpenVPN
- **Windows**: Download OpenVPN GUI from https://openvpn.net/community-downloads/
- **Linux**: `sudo apt install openvpn`
- **macOS**: Download Tunnelblick from https://tunnelblick.net/

### Step 2: Connect to VPN
1. You will receive a `.ovpn` file from your instructor
2. Import it into your OpenVPN client
3. Connect — you should see a successful connection message
4. Verify: `ping 10.10.0.2` should respond

### Step 3: Access Your Team Desktop
1. Open a web browser
2. Navigate to: `http://10.10.0.1:690{your_team_number}`
   - Team 1: http://10.10.0.1:6901
   - Team 2: http://10.10.0.1:6902
   - Team 3: http://10.10.0.1:6903
   - Team 4: http://10.10.0.1:6904
   - Team 5: http://10.10.0.1:6905
3. Enter the VNC password provided by your instructor
4. You now have a desktop with pre-installed security tools

## Your Team's Environment

Your team has 5 vulnerable services running:

| Service             | IP Address        | Port(s)     |
|---------------------|-------------------|-------------|
| Web Server          | 10.10.{N}.20      | 80          |
| SQL App             | 10.10.{N}.30      | 80          |
| File Server         | 10.10.{N}.40      | 21, 80      |
| Packet Challenge    | 10.10.{N}.50      | 80          |
| Misc Service        | 10.10.{N}.60      | 6379, 11211 |

Replace `{N}` with your team number.

## Available Tools (in VNC Desktop)

- `nmap` — Network scanner
- `curl` / `wget` — HTTP clients
- `wireshark` — Packet analyzer
- `sqlmap` — SQL injection tool
- `dirb` / `gobuster` — Directory enumeration
- `netcat (nc)` — Network utility
- `redis-cli` — Redis client
- `python3` — Scripting
- `ftp` — FTP client

## Flag Format

All flags look like:
```
FEIT{some_text_here}
```

When you find a flag, submit it on the scoreboard.

## Submitting Flags

1. Open: http://10.10.0.2:5000
2. Log in with your team credentials (provided by instructor)
3. Paste the flag in the submission box
4. Click Submit
5. If correct, you earn points!

## Scoring

| Challenge Type       | Points |
|----------------------|--------|
| Web Flag             | 100    |
| Hidden File Flag     | 150    |
| SQL Injection Flag   | 200    |
| Packet Capture Flag  | 200    |
| Misconfigured Service| 250    |

## Rules

1. **Stay in the lab network** — Do NOT attack anything outside the VPN
2. **No DoS attacks** — Don't crash or flood other teams' services
3. **No flag tampering** — Don't delete or modify flags in your own services
4. **No sharing flags** — Don't give flags to other teams
5. **No host attacks** — Don't attempt to access the host server (192.168.183.123)
6. **No internet access** — The lab is isolated; don't try to bypass this
7. **Have fun and learn!**

## Tips

- Start with the easier challenges (web source code, hidden files)
- Use `nmap` to discover what's running on each target
- Read error messages carefully — they often contain hints
- Work as a team — divide and conquer the challenges
- Check `robots.txt` on web servers
- Try default/no credentials on services

## Need Help?

Raise your hand or contact your instructor. The admin team monitors the competition and can help with technical issues (not challenge solutions!).

## Important IPs

| Resource        | Address                    |
|-----------------|----------------------------|
| Scoreboard      | http://10.10.0.2:5000      |
| Your Desktop    | http://10.10.0.1:690{N}    |
| Your Services   | 10.10.{N}.20-60            |
| Other Teams     | 10.10.{1-5}.20-60          |
