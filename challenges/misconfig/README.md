# FEIT CTF Challenge 5: Misconfigured Service

## Description
This challenge focuses on identifying and interacting with insecurely configured services. Students must perform service enumeration to discover unauthenticated instances of Redis and Memcached.

## Learning Objectives
- Service enumeration and port scanning.
- Identifying insecure default configurations (no authentication).
- Using `redis-cli` to interact with Redis.
- Using `netcat` (nc) to interact with Memcached.
- Understanding the risks of unauthenticated services exposed to the network.

## Infrastructure
- **IP Range:** `10.10.N.60` (where N is the Team ID 1–5)
- **Services:**
  - **Port 80:** Nginx (Hint landing page)
  - **Port 6379:** Redis (No authentication)
  - **Port 11211:** Memcached (No authentication)

## Setup Instructions
1. Navigate to the challenge directory:
   ```bash
   cd /home/joker/CTF_Misconfigured_Service_Challenge
   ```
2. Deploy the challenge:
   ```bash
   chmod +x deploy.sh generate_flags.sh
   ./deploy.sh
   ```
3. The script will generate unique flags for each team and start the containers.

## Student Workflow (Example for Team 1)

### 1. Enumeration
Start with a port scan to identify open ports:
```bash
nmap -sV 10.10.1.60
```
Output should show ports 80, 6379, and 11211.

### 2. Redis Exploration
Connect to the Redis service:
```bash
redis-cli -h 10.10.1.60
```
Once connected, list keys or try to get the flag:
```bash
10.10.1.60:6379> KEYS *
10.10.1.60:6379> GET flag
```
**Flag 1:** `FEIT{team1_redis_noauth_flag_RANDOM}`

### 3. Memcached Exploration
Interact with Memcached using `netcat`:
```bash
# Check for a hint or secret_flag
echo "get secret_flag" | nc 10.10.1.60 11211
```
**Flag 2:** `FEIT{team1_memcached_flag_RANDOM}`

## Troubleshooting
- **Cannot reach IP:** Ensure the Docker networks `ctf-team1` through `ctf-team5` are correctly routed in your VPN environment.
- **Service down:** Check container status: `docker compose ps`.
- **Redis protected mode:** If Redis refuses connection, ensure `protected-mode no` is set in `redis.conf` and the service is bound to `0.0.0.0`.

## Security Notes
These services are intentionally left unauthenticated for educational purposes. Access should be restricted to the CTF environment.
