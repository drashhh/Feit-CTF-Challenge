# 1. Architecture Proposal

## Host Server Layout (192.168.183.123)

```
+----------------------------------------------------------+
|                  Ubuntu 22.04 Host Server                 |
|                    192.168.183.123                         |
|                                                           |
|  +-------------+  +-------------+  +------------------+  |
|  |  OpenVPN    |  |  Scoreboard |  |  Docker Engine   |  |
|  |  10.8.0.1   |  |  10.10.0.2  |  |                  |  |
|  +-------------+  +-------------+  +------------------+  |
|                                     |                     |
|     +-------------------------------+----------------+    |
|     |               |               |               |    |
|  +--+---+  +-------+--+  +--------+-+  +----------+ |   |
|  |Team 1|  |Team 2    |  |Team 3    |  |Team 4/5  | |   |
|  |10.10 |  |10.10     |  |10.10     |  |10.10     | |   |
|  |.1.0  |  |.2.0      |  |.3.0      |  |.4/5.0   | |   |
|  |/24   |  |/24       |  |/24       |  |/24       | |   |
|  +------+  +----------+  +----------+  +----------+ |   |
+----------------------------------------------------------+
```

## Component Overview

| Component       | Role                                  | Location           |
|-----------------|---------------------------------------|--------------------|
| Host OS         | Ubuntu 22.04, runs Docker + OpenVPN   | 192.168.183.123    |
| OpenVPN Server  | Student VPN access                    | 10.8.0.1           |
| Scoreboard      | Flag submission + scoring web app     | 10.10.0.2:5000     |
| Team Networks   | Isolated Docker bridge per team       | 10.10.{1-5}.0/24   |
| VNC Desktops    | XFCE desktop per team via noVNC       | Ports 6901-6905    |
| Challenge Containers | 5 vulnerable services per team   | Inside team network |

## Docker/Container Layout per Team

Each team gets:
- 1 Docker bridge network (`ctf-team{N}-net`)
- 1 VNC/desktop container (student workspace)
- 5 challenge containers (vulnerable services)
- Connection to the shared scoreboard network

```
Team N Network (10.10.N.0/24)
├── vnc-teamN        (10.10.N.10)  - XFCE desktop with tools
├── web-teamN        (10.10.N.20)  - Web flag challenge
├── sqli-teamN       (10.10.N.30)  - SQL injection challenge
├── files-teamN      (10.10.N.40)  - Hidden files challenge
├── pcap-teamN       (10.10.N.50)  - Packet capture challenge
└── misconfig-teamN  (10.10.N.60)  - Misconfigured service
```

## IP Range Summary

| Network               | CIDR            | Purpose                    |
|------------------------|-----------------|----------------------------|
| VPN Tunnel             | 10.8.0.0/24     | OpenVPN client connections |
| Shared/Scoreboard      | 10.10.0.0/24    | Scoreboard, shared infra  |
| Team 1                 | 10.10.1.0/24    | Team 1 challenges          |
| Team 2                 | 10.10.2.0/24    | Team 2 challenges          |
| Team 3                 | 10.10.3.0/24    | Team 3 challenges          |
| Team 4                 | 10.10.4.0/24    | Team 4 challenges          |
| Team 5                 | 10.10.5.0/24    | Team 5 challenges          |

## VPN Network Design

- OpenVPN runs on host, UDP port 1194
- Each student gets a personal .ovpn file
- VPN assigns IPs from 10.8.0.0/24 pool
- VPN pushes routes to 10.10.0.0/16 so students can reach all team subnets
- No split tunneling — all traffic goes through VPN while connected
- Students cannot reach the internet from the VPN

## VNC/Desktop Access Design

- Each team has one shared VNC desktop container based on `kasmweb/desktop` or `consol/ubuntu-xfce-vnc`
- Accessible via noVNC (web browser) on ports 6901-6905
- Pre-installed tools: nmap, curl, wget, wireshark, sqlmap, dirb, netcat, python3
- No sudo inside VNC containers
- Students connect: `http://10.10.0.1:690{N}` (through VPN)

## Team Isolation Model

1. **Network isolation**: Each team has its own Docker bridge network
2. **Cross-team access**: Teams can reach OTHER teams' challenge containers (attack surface) via routing
3. **Own-team defense**: Teams monitor/defend their own services
4. **No host access**: Docker networks are configured to block gateway access (host)
5. **No internet**: iptables blocks outbound internet from all Docker/VPN subnets
6. **Scoreboard access**: All teams connect to shared scoreboard network
