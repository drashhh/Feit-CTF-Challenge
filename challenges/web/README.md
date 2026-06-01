# Challenge 1: Web Flag

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
