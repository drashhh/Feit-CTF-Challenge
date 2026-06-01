# 2. Network Design

## VPN Configuration

### OpenVPN Server
- Protocol: UDP
- Port: 1194
- Subnet: 10.8.0.0/24
- Server IP: 10.8.0.1
- Client range: 10.8.0.2 - 10.8.0.254
- Encryption: AES-256-GCM
- Auth: SHA256
- TLS: tls-crypt

### Client Routing
Pushed routes to all team subnets:
```
push "route 10.10.0.0 255.255.0.0"
```

### DNS
No DNS pushed — students should not need DNS resolution inside the lab.

## Firewall Rules Summary

### Host Firewall (UFW/iptables)

```
# Allow SSH from anywhere (admin access)
ufw allow 22/tcp

# Allow OpenVPN
ufw allow 1194/udp

# Allow noVNC ports (only from VPN subnet)
ufw allow from 10.8.0.0/24 to any port 6901:6905 proto tcp

# Allow scoreboard (only from VPN subnet)
ufw allow from 10.8.0.0/24 to any port 5000 proto tcp

# Block internet from VPN clients
iptables -I FORWARD -s 10.8.0.0/24 -o eth0 -j DROP
iptables -I FORWARD -s 10.8.0.0/24 -d 10.10.0.0/16 -j ACCEPT

# Block internet from Docker subnets
iptables -I FORWARD -s 10.10.0.0/16 -o eth0 -j DROP
iptables -I FORWARD -s 10.10.0.0/16 -d 10.10.0.0/16 -j ACCEPT
iptables -I FORWARD -s 10.10.0.0/16 -d 10.8.0.0/24 -j ACCEPT
```

### Docker Network Restrictions
- All team Docker networks use `internal: false` but with iptables rules blocking internet
- `com.docker.network.bridge.enable_ip_masquerade: "false"` on team networks
- Gateway access blocked via `com.docker.network.bridge.host_binding_ipv4: "10.10.0.1"`

## Network Diagram

```
Internet
    |
    | (blocked for students)
    |
[eth0 - 192.168.183.123]
    |
    +--- [tun0 - OpenVPN - 10.8.0.1/24]
    |         |
    |         +--- Student VPN clients (10.8.0.2-254)
    |
    +--- [docker0]
    |         |
    |         +--- [br-shared - 10.10.0.0/24]
    |         |         +--- scoreboard (10.10.0.2)
    |         |
    |         +--- [br-team1 - 10.10.1.0/24]
    |         |         +--- vnc-team1    (10.10.1.10)
    |         |         +--- web-team1    (10.10.1.20)
    |         |         +--- sqli-team1   (10.10.1.30)
    |         |         +--- files-team1  (10.10.1.40)
    |         |         +--- pcap-team1   (10.10.1.50)
    |         |         +--- misconfig-team1 (10.10.1.60)
    |         |
    |         +--- [br-team2 - 10.10.2.0/24]
    |         |         +--- (same structure)
    |         |
    |         +--- [br-team3..5 - 10.10.3-5.0/24]
    |                   +--- (same structure)
    |
    +--- [Host services: SSH on 22, OpenVPN on 1194]
```

## Port Assignments

| Service          | Port(s)     | Accessible From     |
|------------------|-------------|---------------------|
| SSH (admin)      | 22/tcp      | Admin network only  |
| OpenVPN          | 1194/udp    | Students (external) |
| Scoreboard       | 5000/tcp    | VPN clients         |
| noVNC Team 1     | 6901/tcp    | VPN clients         |
| noVNC Team 2     | 6902/tcp    | VPN clients         |
| noVNC Team 3     | 6903/tcp    | VPN clients         |
| noVNC Team 4     | 6904/tcp    | VPN clients         |
| noVNC Team 5     | 6905/tcp    | VPN clients         |
| Challenge HTTP   | 80/team net | Cross-team via VPN  |
| Challenge MySQL  | 3306/team   | Within team net     |
| Challenge FTP    | 21/team net | Cross-team via VPN  |
| Challenge Redis  | 6379/team   | Cross-team via VPN  |
