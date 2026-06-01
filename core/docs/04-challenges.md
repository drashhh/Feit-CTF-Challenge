# 4. Challenge Descriptions

## Challenge 1: Web Flag (100 points)

### Learning Objective
Teach students to inspect web page source code, HTTP headers, and HTML comments for hidden information.

### Setup
- Simple HTML/CSS website served by Nginx
- Flag hidden in an HTML comment in the source code
- A second flag in a custom HTTP response header (`X-Secret-Flag`)

### Where the Flag is Stored
1. HTML comment: `<!-- Debug: FEIT{team{N}_web_source_flag_XXXX} -->`
2. HTTP header: `X-Secret-Flag: FEIT{team{N}_http_header_flag_XXXX}`

### Deployment
- Docker container running Nginx with a static HTML site
- Container: `web-team{N}` on port 80
- IP: `10.10.{N}.20`

### What Students Discover
- Right-click > View Source reveals the HTML comment flag
- Using `curl -I` or browser dev tools reveals the header flag

### Difficulty
Beginner. Most students should find this within 5-10 minutes.

### Fairness
Both flags are always present and don't require any exploitation — just observation.

---

## Challenge 2: SQL Injection (200 points)

### Learning Objective
Understand SQL injection vulnerabilities, how unsanitized input leads to data leaks.

### Setup
- PHP web application with a login form
- Backend: MySQL database
- Login query is vulnerable: `SELECT * FROM users WHERE username='$user' AND password='$pass'`
- Flag stored in a separate `secrets` table

### Where the Flag is Stored
- MySQL table `secrets`: `FEIT{team{N}_sqli_database_flag_XXXX}`
- Accessible via UNION-based SQL injection

### Deployment
- Docker container running Apache + PHP + MySQL
- Container: `sqli-team{N}` on port 80 (web) and 3306 (MySQL, internal)
- IP: `10.10.{N}.30`

### What Students Discover
1. Login form is vulnerable to `' OR 1=1 --`
2. Using `' UNION SELECT 1,2,flag FROM secrets --` extracts the flag
3. Tools like `sqlmap` can also automate this

### Difficulty
Beginner-Intermediate. Classic UNION injection.

### Fairness
- The login form has a visible hint ("Try logging in as admin")
- Only basic SQL injection is needed — no blind/time-based

---

## Challenge 3: Hidden Directory/File Flag (150 points)

### Learning Objective
Learn directory enumeration, finding backup files, and recognizing common misconfigurations in file servers.

### Setup
- FTP server (vsftpd) with anonymous login enabled
- A hidden directory `.backup/` containing a flag file
- A `robots.txt` on a companion web server hinting at `/secret/`
- The `/secret/` directory contains a `flag.txt`

### Where the Flag is Stored
1. FTP: `/.backup/admin_notes.txt` contains `FEIT{team{N}_hidden_ftp_flag_XXXX}`
2. Web: `/secret/flag.txt` contains `FEIT{team{N}_hidden_web_flag_XXXX}`

### Deployment
- Docker container running vsftpd + Nginx
- Container: `files-team{N}` on ports 21 (FTP) and 80 (HTTP)
- IP: `10.10.{N}.40`

### What Students Discover
- `ftp 10.10.{N}.40` with anonymous login, then `ls -la` reveals `.backup/`
- `dirb http://10.10.{N}.40` or checking `robots.txt` reveals `/secret/`

### Difficulty
Beginner. Teaches enumeration fundamentals.

### Fairness
- Anonymous FTP is clearly enabled (no credentials needed)
- `robots.txt` provides a deliberate clue

---

## Challenge 4: Packet Capture / Wireshark Flag (200 points)

### Learning Objective
Analyze network traffic captures, identify cleartext protocols, extract data from packet captures.

### Setup
- Container serves a `.pcap` file via HTTP download
- The pcap contains simulated HTTP traffic with a flag in a POST request body
- Also contains a flag in a DNS TXT record query

### Where the Flag is Stored
1. HTTP POST body in pcap: `FEIT{team{N}_pcap_http_flag_XXXX}`
2. DNS TXT record in pcap: `FEIT{team{N}_pcap_dns_flag_XXXX}`

### Deployment
- Docker container running Nginx, serving the pcap file at `/capture.pcap`
- Container: `pcap-team{N}` on port 80
- IP: `10.10.{N}.50`
- The pcap file is pre-generated during setup (using `scapy` or `tcpreplay`)

### What Students Discover
1. Download: `wget http://10.10.{N}.50/capture.pcap`
2. Open in Wireshark (available in VNC desktop)
3. Filter HTTP traffic, inspect POST body
4. Filter DNS traffic, inspect TXT record responses

### Difficulty
Intermediate. Requires familiarity with Wireshark filters.

### Fairness
- The pcap is small (~50 packets) so it's not overwhelming
- Hint page on the web server says "Analyze the network capture carefully"

---

## Challenge 5: Misconfigured Service Flag (250 points)

### Learning Objective
Identify and exploit misconfigured services — services running without authentication or with default credentials.

### Setup
- Redis server running without authentication (`requirepass` not set)
- Flag stored as a Redis key
- A secondary flag in a Memcached instance with no auth

### Where the Flag is Stored
1. Redis key `flag`: `FEIT{team{N}_redis_noauth_flag_XXXX}`
2. Memcached key `secret_flag`: `FEIT{team{N}_memcached_flag_XXXX}`

### Deployment
- Docker container running Redis (port 6379) and Memcached (port 11211)
- Container: `misconfig-team{N}`
- IP: `10.10.{N}.60`

### What Students Discover
1. Port scan: `nmap 10.10.{N}.60` reveals open ports 6379 and 11211
2. `redis-cli -h 10.10.{N}.60` then `GET flag` retrieves the Redis flag
3. `echo "get secret_flag" | nc 10.10.{N}.60 11211` retrieves the Memcached flag

### Difficulty
Intermediate. Requires knowing how to interact with these services.

### Fairness
- Services are standard and well-documented
- Students have `redis-cli` and `netcat` pre-installed in VNC desktop
- Hint: "Not everything needs a password"
