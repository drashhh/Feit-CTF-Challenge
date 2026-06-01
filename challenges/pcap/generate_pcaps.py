import os
from scapy.all import *
from scapy.layers.inet import IP, TCP, ICMP
from scapy.layers.dns import DNS, DNSQR, DNSRR
from scapy.layers.l2 import Ether

def generate_team_pcap(team_num, http_flag, dns_flag, output_path):
    packets = []
    
    src_ip = f"10.10.{team_num}.100"
    dst_ip = f"10.10.{team_num}.50"
    dns_server = "8.8.8.8"
    
    # 1. Normal TCP Handshake
    sport = 45678
    seq = 1000
    # SYN
    packets.append(IP(src=src_ip, dst=dst_ip)/TCP(sport=sport, dport=80, flags="S", seq=seq))
    # SYN-ACK
    packets.append(IP(src=dst_ip, dst=src_ip)/TCP(sport=80, dport=sport, flags="SA", seq=2000, ack=seq+1))
    # ACK
    packets.append(IP(src=src_ip, dst=dst_ip)/TCP(sport=sport, dport=80, flags="A", seq=seq+1, ack=2001))
    
    # 2. HTTP GET Request
    get_payload = "GET /index.html HTTP/1.1\r\nHost: portal.feit.edu\r\nUser-Agent: Mozilla/5.0\r\n\r\n"
    packets.append(IP(src=src_ip, dst=dst_ip)/TCP(sport=sport, dport=80, flags="PA", seq=seq+1, ack=2001)/get_payload)
    # HTTP OK
    ok_payload = "HTTP/1.1 200 OK\r\nContent-Length: 15\r\n\r\nWelcome to FEIT"
    packets.append(IP(src=dst_ip, dst=src_ip)/TCP(sport=80, dport=sport, flags="PA", seq=2001, ack=seq+len(get_payload)+1)/ok_payload)

    # 3. HTTP POST Request (THE FLAG)
    post_data = f"username=admin&session_token=xyz&flag={http_flag}"
    post_payload = f"POST /login HTTP/1.1\r\nHost: portal.feit.edu\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: {len(post_data)}\r\n\r\n{post_data}"
    packets.append(IP(src=src_ip, dst=dst_ip)/TCP(sport=sport+1, dport=80, flags="PA", seq=seq+500, ack=3000)/post_payload)
    
    # 4. DNS Traffic (THE OTHER FLAG)
    # DNS A Query (Noise)
    packets.append(IP(src=src_ip, dst=dns_server)/UDP(sport=5353, dport=53)/DNS(rd=1, qd=DNSQR(qname="google.com")))
    packets.append(IP(src=dns_server, dst=src_ip)/UDP(sport=53, dport=5353)/DNS(id=packets[-1][DNS].id, qr=1, aa=1, qd=DNSQR(qname="google.com"), an=DNSRR(rrname="google.com", rdata="142.250.190.46")))
    
    # DNS TXT Query
    packets.append(IP(src=src_ip, dst=dns_server)/UDP(sport=5354, dport=53)/DNS(rd=1, qd=DNSQR(qname="flag.feit.edu", qtype="TXT")))
    # DNS TXT Response (FLAG)
    packets.append(IP(src=dns_server, dst=src_ip)/UDP(sport=53, dport=5354)/DNS(id=packets[-1][DNS].id, qr=1, aa=1, qd=DNSQR(qname="flag.feit.edu", qtype="TXT"), an=DNSRR(rrname="flag.feit.edu", type="TXT", rdata=dns_flag)))
    
    # 5. Harmless filler
    for i in range(3):
        packets.append(IP(src=src_ip, dst=dst_ip)/ICMP())
        packets.append(IP(src=dst_ip, dst=src_ip)/ICMP(type=0))

    wrpcap(output_path, packets)

if __name__ == "__main__":
    import sys
    # Load flags from env or args
    # For automation, we'll read the flags.env file
    flags = {}
    if os.path.exists("flags.env"):
        with open("flags.env", "r") as f:
            for line in f:
                k, v = line.strip().split("=")
                flags[k] = v
    
    for i in range(1, 6):
        http = flags.get(f"TEAM{i}_HTTP_FLAG", f"FEIT{{team{i}_default_http}}")
        dns = flags.get(f"TEAM{i}_DNS_FLAG", f"FEIT{{team{i}_default_dns}}")
        path = f"teams/team{i}/website/capture.pcap"
        os.makedirs(os.path.dirname(path), exist_ok=True)
        generate_team_pcap(i, http, dns, path)
        print(f"Generated {path}")
