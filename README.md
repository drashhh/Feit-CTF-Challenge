# FEIT CTF Project Bundle

This repository contains the complete infrastructure and challenge source for the FEIT Cyber Security CTF. It is designed for rapid deployment on a fresh Linux server using Docker and OpenVPN.

## Repository Structure

- `core/`: Primary infrastructure components.
  - `docker/`: Main orchestration for the Scoreboard, shared networks, and common services.
  - `vpn/`: OpenVPN server configuration and client profile generation.
  - `scripts/`: Administrative scripts for flag generation, backups, and server setup.
  - `docs/`: Technical documentation and administrator guides.
- `challenges/`: Modular CTF challenges.
  - `web/`: Web application vulnerabilities (Source inspection, Header manipulation).
  - `linux/`: Linux systems administration and privilege escalation.
  - `pcap/`: Network traffic analysis (Packet Capture).
  - `misconfig/`: Insecure service configurations (Redis, Memcached).
  - `hidden-files/`: Information disclosure through FTP and Web.
- `setup_all.sh`: Master automation script for one-click deployment.

## Deployment Instructions

### Prerequisites
- **OS**: Ubuntu 22.04 LTS (Recommended) or Debian 12.
- **Hardware**: Minimum 4GB RAM, 2 vCPUs.
- **Root access**: Required for network and package configuration.

### One-Click Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/your-org/feit-ctf-bundle.git
   cd feit-ctf-bundle
   ```
2. Run the master setup script:
   ```bash
   sudo chmod +x setup_all.sh
   sudo ./setup_all.sh
   ```

The script will automatically install Docker, configure isolated team networks, generate unique flags, and start all services.

## Configuration

### Environment Variables
Before deployment, you can customize passwords and secrets in `core/docker/.env.example`.
```bash
cp core/docker/.env.example core/docker/.env
# Edit core/docker/.env with your desired settings
```

### VPN Access
Student `.ovpn` profiles are generated during setup.
- Location: `core/vpn/clients/`
- Each student requires a unique profile to connect to the internal `10.10.0.0/16` network.

## Scoreboard
The scoring platform is available at:
- **URL**: `http://10.10.0.2:5000` (Inside VPN)
- **Admin**: Credentials are generated in `core/docker/.env` during setup.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Security
Please report any vulnerabilities to the maintainers. See [SECURITY.md](SECURITY.md) for our security policy.
