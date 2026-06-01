import os

# Use relative path based on script location
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

docker_compose = """version: '3.8'

services:
  web-team1:
    build: ./teams/team1
    container_name: web-team1
    networks:
      team1_net:
        ipv4_address: 10.10.1.20
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 30s
      timeout: 10s
      retries: 3

  web-team2:
    build: ./teams/team2
    container_name: web-team2
    networks:
      team2_net:
        ipv4_address: 10.10.2.20
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 30s
      timeout: 10s
      retries: 3

  web-team3:
    build: ./teams/team3
    container_name: web-team3
    networks:
      team3_net:
        ipv4_address: 10.10.3.20
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 30s
      timeout: 10s
      retries: 3

  web-team4:
    build: ./teams/team4
    container_name: web-team4
    networks:
      team4_net:
        ipv4_address: 10.10.4.20
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 30s
      timeout: 10s
      retries: 3

  web-team5:
    build: ./teams/team5
    container_name: web-team5
    networks:
      team5_net:
        ipv4_address: 10.10.5.20
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  team1_net:
    driver: bridge
    ipam:
      config:
        - subnet: 10.10.1.0/24
  team2_net:
    driver: bridge
    ipam:
      config:
        - subnet: 10.10.2.0/24
  team3_net:
    driver: bridge
    ipam:
      config:
        - subnet: 10.10.3.0/24
  team4_net:
    driver: bridge
    ipam:
      config:
        - subnet: 10.10.4.0/24
  team5_net:
    driver: bridge
    ipam:
      config:
        - subnet: 10.10.5.0/24
"""

deploy_sh = """#!/bin/bash
# Colors
GREEN='\\033[0;32m'
BLUE='\\033[0;34m'
YELLOW='\\033[0;33m'
NC='\\033[0m'

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE} Deploying FEIT CTF Web Challenge ${NC}"
echo -e "${BLUE}==========================================${NC}"

# 1. Generate Flags
echo -e "\\n${YELLOW}[1/4] Generating unique flags...${NC}"
chmod +x generate_flags.sh
./generate_flags.sh

# 2. Build Containers
echo -e "\\n${YELLOW}[2/4] Building Docker containers...${NC}"
docker-compose build

# 3. Start Containers
echo -e "\\n${YELLOW}[3/4] Starting Docker containers & Networks...${NC}"
docker-compose up -d

# 4. Verify & IP Details
echo -e "\\n${YELLOW}[4/4] Verifying containers and networking...${NC}"
sleep 3

echo -e "\\n${GREEN}Deployment Successful! Access details:${NC}"
echo "--------------------------------------------------"
printf "%-10s %-15s %-15s\\n" "Team" "Container" "IP Address"
echo "--------------------------------------------------"

for i in {1..5}; do
    CONTAINER="web-team${i}"
    IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CONTAINER 2>/dev/null)
    if [ -z "$IP" ]; then
        IP="Not Running"
    fi
    printf "%-10s %-15s %-15s\\n" "Team $i" "$CONTAINER" "$IP"
done

echo "--------------------------------------------------"
echo -e "\\n${GREEN}Challenge is live! Check README.md for testing instructions.${NC}"
"""

generate_flags_sh = """#!/bin/bash
GREEN='\\033[0;32m'
BLUE='\\033[0;34m'
NC='\\033[0m'

echo -e "${BLUE}Generating unique flags for all teams...${NC}"

for i in {1..5}; do
    TEAM_DIR="teams/team${i}"
    
    if [ ! -d "$TEAM_DIR" ]; then
        echo "Error: Directory $TEAM_DIR not found!"
        continue
    fi
    
    # Generate random 4-character hex strings
    RAND_HTML=$(openssl rand -hex 2 | tr 'a-z' 'A-Z')
    RAND_HEADER=$(openssl rand -hex 2 | tr 'a-z' 'A-Z')
    
    HTML_FLAG="FEIT{team${i}_web_source_flag_${RAND_HTML}}"
    HEADER_FLAG="FEIT{team${i}_http_header_flag_${RAND_HEADER}}"
    
    # Insert or update HTML flag in index.html
    if grep -q "HTML_FLAG_PLACEHOLDER" "$TEAM_DIR/index.html"; then
        sed -i "s/<!-- HTML_FLAG_PLACEHOLDER -->/<!-- Debug: ${HTML_FLAG} -->/g" "$TEAM_DIR/index.html"
    else
        sed -i -E "s/<!-- Debug: FEIT\\{team${i}_web_source_flag_[A-Z0-9]{4}\\} -->/<!-- Debug: ${HTML_FLAG} -->/g" "$TEAM_DIR/index.html"
    fi
    
    # Insert or update Header flag in nginx.conf
    if grep -q "HEADER_FLAG_PLACEHOLDER" "$TEAM_DIR/nginx.conf"; then
        sed -i "s/HEADER_FLAG_PLACEHOLDER/${HEADER_FLAG}/g" "$TEAM_DIR/nginx.conf"
    else
        sed -i -E "s/X-Secret-Flag \\"FEIT\\{team${i}_http_header_flag_[A-Z0-9]{4}\\}\\"/X-Secret-Flag \\"${HEADER_FLAG}\\"/g" "$TEAM_DIR/nginx.conf"
    fi
    
    echo -e "${GREEN}Team $i Flags Generated:${NC}"
    echo "  HTML:   $HTML_FLAG"
    echo "  Header: $HEADER_FLAG"
done

echo -e "${BLUE}Flag generation complete!${NC}"
"""

readme_md = """# Challenge 1: Web Flag

## Overview
This is a beginner-friendly CTF challenge teaching students how to inspect HTML source code and HTTP response headers. Each team gets an isolated Docker container with a unique web instance and flags.

## Setup Instructions
1. Ensure Docker and `docker-compose` are installed.
2. Run the deployment script:
   ```bash
   sudo ./deploy.sh
   ```
   *This automatically generates unique flags, builds containers, establishes the isolated bridge networks, and prints static IPs.*

## Testing & Verification
### Method 1: Browser
1. Navigate to `http://10.10.X.20` (Replace X with team number 1-5).
2. **HTML Flag**: Right-click on the page -> **View Page Source**. Look for the `<!-- Debug: FEIT{...} -->` comment.
3. **Header Flag**: Open Developer Tools (F12) -> **Network** tab -> Refresh -> Click the main document -> Check the **Response Headers** for `X-Secret-Flag`.

### Method 2: Command Line (cURL)
**Fetch the HTML flag:**
```bash
curl -s http://10.10.1.20 | grep "FEIT{"
```

**Fetch the Header flag:**
```bash
curl -I http://10.10.1.20 | grep "X-Secret-Flag"
```

## Troubleshooting
- If a container isn't starting, view logs: `docker logs web-team1`
- To completely reset: `docker-compose down` followed by `./deploy.sh`
"""

dockerfile_content = """FROM nginx:alpine
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/
COPY index.html /usr/share/nginx/html/
COPY style.css /usr/share/nginx/html/
RUN apk add --no-cache curl
EXPOSE 80
"""

nginx_conf = """server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;
    server_tokens off;
    autoindex off;
    add_header X-Secret-Flag "HEADER_FLAG_PLACEHOLDER";
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-XSS-Protection "1; mode=block";
    location / { try_files $uri $uri/ =404; }
}
"""

style_css = """* { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
body { background-color: #e9ecef; color: #333; display: flex; justify-content: center; align-items: center; min-height: 100vh; }
.container { background: #fff; padding: 2.5rem; border-radius: 8px; box-shadow: 0 4px 20px rgba(0,0,0,0.05); width: 100%; max-width: 450px; }
header { text-align: center; margin-bottom: 2rem; border-bottom: 3px solid #0056b3; padding-bottom: 1rem; }
header h1 { color: #0056b3; font-size: 1.6rem; margin-bottom: 0.5rem; text-transform: uppercase; letter-spacing: 1px;}
header p { color: #6c757d; font-size: 1rem; font-weight: 500;}
.login-section h2 { margin-bottom: 1.5rem; font-size: 1.3rem; color: #495057; text-align: center;}
.input-group { margin-bottom: 1.2rem; }
.input-group label { display: block; margin-bottom: 0.5rem; font-weight: 600; color: #495057; font-size: 0.9rem;}
.input-group input { width: 100%; padding: 0.8rem; border: 1px solid #ced4da; border-radius: 4px; font-size: 1rem; transition: border-color 0.3s;}
.input-group input:focus { border-color: #0056b3; outline: none; }
.btn { width: 100%; padding: 0.8rem; background-color: #0056b3; color: white; border: none; border-radius: 4px; font-size: 1.1rem; font-weight: 600; cursor: pointer; transition: background 0.3s; margin-top: 1rem;}
.btn:hover { background-color: #004494; }
.hints { margin-top: 2rem; padding: 1.2rem; background-color: #f8f9fa; border-left: 4px solid #17a2b8; border-radius: 4px; }
.hints h3 { font-size: 1.1rem; margin-bottom: 0.5rem; color: #212529; }
.hints p { font-size: 0.9rem; color: #495057; line-height: 1.5; }
"""

index_html_template = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FEIT Cyber Security Challenge - Team {TEAM_NUM}</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <!-- HTML_FLAG_PLACEHOLDER -->
    <div class="container">
        <header>
            <h1>FEIT Cyber Security Challenge</h1>
            <p>Team {TEAM_NUM} - Student Portal</p>
        </header>
        <main>
            <section class="login-section">
                <h2>Portal Login</h2>
                <form action="#" method="POST" onsubmit="event.preventDefault(); alert('Authentication servers are currently down for maintenance.');">
                    <div class="input-group">
                        <label for="username">Username</label>
                        <input type="text" id="username" name="username" value="{USERNAME}" required>
                    </div>
                    <div class="input-group">
                        <label for="password">Password</label>
                        <input type="password" id="password" name="password" placeholder="Enter password (e.g., {PASSWORD})" required>
                    </div>
                    <button type="submit" class="btn">Sign In</button>
                </form>
            </section>
            <section class="hints">
                <h3>System Status</h3>
                <p>Welcome <b>{USERNAME}</b>! All systems operational. Remember: Developers sometimes leave debug information in the application. Inspect your surroundings carefully.</p>
            </section>
        </main>
    </div>
</body>
</html>"""

import os

def write_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

write_file(f"{BASE_DIR}/docker-compose.yml", docker_compose)
write_file(f"{BASE_DIR}/deploy.sh", deploy_sh)
write_file(f"{BASE_DIR}/generate_flags.sh", generate_flags_sh)
write_file(f"{BASE_DIR}/README.md", readme_md)

os.chmod(f"{BASE_DIR}/deploy.sh", 0o755)
os.chmod(f"{BASE_DIR}/generate_flags.sh", 0o755)

teams = [
    (1, "Korisnik1", "password1"),
    (2, "Korisnik2", "password2"),
    (3, "Korisnik3", "password3"),
    (4, "Korisnik4", "password4"),
    (5, "Korisnik5", "password5"),
]

for team_num, username, password in teams:
    team_dir = f"{BASE_DIR}/teams/team{team_num}"
    write_file(f"{team_dir}/Dockerfile", dockerfile_content)
    write_file(f"{team_dir}/nginx.conf", nginx_conf)
    write_file(f"{team_dir}/style.css", style_css)
    
    html_content = index_html_template.replace("{TEAM_NUM}", str(team_num)).replace("{USERNAME}", username).replace("{PASSWORD}", password)
    write_file(f"{team_dir}/index.html", html_content)

print("Files successfully generated.")