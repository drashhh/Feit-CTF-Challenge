# Challenge 4: Packet Capture / Wireshark Flag

## Overview
This intermediate-level challenge requires students to analyze network traffic to uncover hidden flags. It focuses on:
- Identifying protocols (HTTP, DNS)
- Inspecting request/response bodies
- Extracting data from non-HTTP protocols (DNS TXT)

## Student Discovery Workflow
1. **Download the capture file:**
   ```bash
   wget http://10.10.X.50/capture.pcap
   ```
2. **Open in Wireshark:**
   ```bash
   wireshark capture.pcap
   ```
3. **Analyze HTTP Traffic:**
   - Filter by `http`.
   - Look for a `POST` request.
   - Inspect the **HTML Form URL Encoded** body to find the `FEIT{..._http_flag_...}`.
4. **Analyze DNS Traffic:**
   - Filter by `dns`.
   - Look for a `TXT` record query for `flag.feit.edu`.
   - Inspect the corresponding response to find the `FEIT{..._pcap_dns_flag_...}` in the Answers section.

## Alternative Analysis (Command Line)
**Extract HTTP flag with tshark:**
```bash
tshark -r capture.pcap -Y "http.request.method == POST" -T fields -e text
```

**Extract DNS flag with tshark:**
```bash
tshark -r capture.pcap -Y "dns.txt" -T fields -e dns.txt
```

## Setup Instructions
1. Navigate to the project directory:
   ```bash
   cd CTF_Packet_Capture_Challenge
   ```
2. Run the deployment script:
   ```bash
   sudo ./deploy.sh
   ```

## Troubleshooting
- **PCAP not downloading:** Check `docker ps` to ensure the container is running.
- **Empty PCAP:** Ensure the `generate_pcaps.py` script ran successfully (checked in `deploy.sh`).
- **Network Conflicts:** Ensure no other services are using the `10.10.X.0/24` subnets.
