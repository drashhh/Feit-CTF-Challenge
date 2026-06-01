# Challenge 3: Hidden Directory/File Flag

## Overview
This beginner-friendly CTF challenge teaches students essential enumeration skills:
- Anonymous FTP access and directory listing
- Finding hidden directories/files (dotfiles)
- Using `ls -la` in FTP
- Inspecting `robots.txt` for web hints
- Basic web directory enumeration with tools like `dirb` or `gobuster`

## Architecture
- **Web Server:** Nginx hosting a fake "secure file server" landing page.
- **FTP Server:** vsftpd configured for read-only anonymous access.
- **Networking:** Custom Docker bridge networks with static IPs (10.10.1.40 through 10.10.5.40).

## Setup Instructions
1. Navigate to the project directory:
   ```bash
   cd CTF_Hidden_Files_Challenge
   ```
2. Run the deployment script:
   ```bash
   sudo ./deploy.sh
   ```
   *This automatically generates unique flags, builds the containers, and deploys the challenge.*

## Testing & Verification

### Web Challenge (Team 1 Example)
1. Navigate to `http://10.10.1.40` in a browser or use `curl`:
   ```bash
   curl -s http://10.10.1.40
   ```
2. Check `robots.txt`:
   ```bash
   curl -s http://10.10.1.40/robots.txt
   ```
   *Output should show `Disallow: /secret/`*
3. Retrieve the web flag:
   ```bash
   curl -s http://10.10.1.40/secret/flag.txt
   ```
4. **Directory Enumeration Alternative:**
   ```bash
   gobuster dir -u http://10.10.1.40 -w /usr/share/wordlists/dirb/common.txt
   # OR
   dirb http://10.10.1.40
   ```

### FTP Challenge (Team 1 Example)
1. Connect to the FTP server:
   ```bash
   ftp 10.10.1.40
   ```
2. Log in with:
   - **Name:** `anonymous`
   - **Password:** `anonymous` (or blank)
3. Enumerate directories:
   ```ftp
   ftp> ls -la
   ```
   *You should see a `.backup` directory.*
4. Retrieve the FTP flag:
   ```ftp
   ftp> cd .backup
   ftp> get admin_notes.txt
   ftp> exit
   ```
   *Then read the file locally with `cat admin_notes.txt`.*

## Troubleshooting
- **Network Conflicts:** If `docker compose up` fails with a network overlap error, you likely have the main CTF infrastructure running. Stop it using `docker compose down` in the `~/CTF/docker` directory.
- **Logs:** View container logs with `docker logs files-team1`.
- **FTP Passive Mode:** The containers are configured with passive ports 30000-30009. Ensure these ports are accessible if testing from outside the host.
