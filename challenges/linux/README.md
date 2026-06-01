# Linux Command-Line Admin & Forensics Challenge

## Overview
This challenge introduces a multi-user Linux environment where all five teams operate on the same host but log in as distinct users. It tests their ability to perform Linux forensics, search the file system efficiently, and manage user sessions.

### Key Objectives
1. **File System Investigation:** Students must find their team's hidden flag, which is stored in a randomly generated, deeply nested directory (e.g., `/var/lib/cache/.x8f9a2/.system_config`). 
2. **Session Termination (Offensive Admin):** Teams must discover and use a custom script (`sudo kick_competitor <username>`) to selectively terminate the SSH/Bash sessions of competing teams.

## User Accounts (Teams 1 - 5)
Each team connects to their specific IP address at `10.10.X.70` via SSH (Port 22), where X is the team number (1-5).
- **Team 1 (M3):** `ssh m3@10.10.1.70` | Password: `RandomForest`
- **Team 2:** `ssh korisnik2@10.10.2.70` | Password: `Securepassword`
- **Team 3:** `ssh korisnik3@10.10.3.70` | Password: `Passwordpassword`
- **Team 4:** `ssh korisnik4@10.10.4.70` | Password: `Scoopaffogato`
- **Team 5 (Demure Hakerz):** `ssh demurehakerz@10.10.5.70` | Password: `Zhapongallery`

## Architecture Details
- **Docker Isolation:** A single Ubuntu 22.04 container (`linux-challenge`) is deployed on the `ctf-shared` network.
- **Security:** Root login is disabled. Users cannot read each other's home directories by default, but the flags are hidden in world-readable but obscure locations.
- **Scoreboard Sync:** The deployment script (`deploy.sh`) automatically generates random flags and directory paths, creates them inside the container, and instantly synchronizes them with the global CTF Scoreboard SQLite database and JSON file under the challenge name `linux_fs`.

## Deployment Instructions
1. Navigate to the project directory:
   ```bash
   cd /home/joker/CTF_Linux_Challenge
   ```
2. Execute the deployment script:
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```
3. (Optional) Check the `generated_flags_log.txt` file in this directory to see exactly where each team's flag was hidden for this specific deployment run.

## Solving the Challenge
**Step 1: SSH Login**
```bash
ssh m3@10.10.1.70
```

**Step 2: Find the Flag**
The flags are in format `FEIT{teamN_linux_fs_flag_XXXXXX}`. Teams can use `find` or `grep` to search the filesystem:
```bash
# Example search command (ignoring permission denied errors):
find / -type f -name ".system_config" 2>/dev/null
# Or search by file contents:
grep -r -l "FEIT{" /opt /var /srv /tmp /usr/local/src 2>/dev/null
```

**Step 3: Kick a Competitor**
To demonstrate session control, a team can run the provided script as root without a password:
```bash
sudo kick_competitor korisnik2
```
This safely kills only the `sshd` and `bash` processes owned by `korisnik2`, effectively logging them out without harming the container or other teams.
