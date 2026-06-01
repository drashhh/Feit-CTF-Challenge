import subprocess
import json
import sqlite3
import os

def run_cmd(cmd):
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.stdout.strip()

def get_flag_from_container(container, path):
    return run_cmd(f"docker exec {container} cat {path} 2>/dev/null")

def get_env_from_container(container, env_var):
    return run_cmd(f"docker exec {container} env | grep {env_var}= | cut -d= -f2")

# Points configuration
POINTS = {
    "web_source": 100,
    "web_header": 100,
    "sqli_database": 200,
    "hidden_ftp": 150,
    "hidden_web": 150,
    "hidden_web_hmac": 175,
    "pcap_http": 200,
    "pcap_dns": 200,
    "redis_noauth": 250,
    "memcached": 250
}

teams = ["team1", "team2", "team3", "team4", "team5"]
all_extracted_flags = []

for i in range(1, 6):
    team_id = f"team{i}"
    print(f"Syncing {team_id}...")

    # 1. Web Challenge
    web_container = f"web-team{i}"
    all_extracted_flags.append({
        "team": team_id, "challenge": "web_source",
        "flag": run_cmd(f"docker exec {web_container} grep -o 'FEIT{{[^}}]*}}' /usr/share/nginx/html/index.html | head -n 1"),
        "points": POINTS["web_source"]
    })
    all_extracted_flags.append({
        "team": team_id, "challenge": "web_header",
        "flag": run_cmd(f"docker exec {web_container} grep -o 'FEIT{{[^}}]*}}' /etc/nginx/conf.d/default.conf | head -n 1"),
        "points": POINTS["web_header"]
    })

    # 2. SQLi Challenge
    sqli_container = f"sqli-team{i}"
    all_extracted_flags.append({
        "team": team_id, "challenge": "sqli_database",
        "flag": get_flag_from_container(sqli_container, "/opt/flag.txt"),
        "points": POINTS["sqli_database"]
    })

    # 3. Hidden Files Challenge
    files_container = f"files-team{i}"
    ftp_raw = get_flag_from_container(files_container, "/srv/ftp/.backup/admin_notes.txt")
    ftp_decoded = bytes.fromhex(ftp_raw).decode('utf-8') if ftp_raw else ""
    all_extracted_flags.append({
        "team": team_id, "challenge": "hidden_ftp",
        "flag": ftp_decoded,
        "points": POINTS["hidden_ftp"]
    })
    web_raw = get_flag_from_container(files_container, "/var/www/html/secret/flag1")
    web_decoded = bytes.fromhex(web_raw).decode('utf-8') if web_raw else ""
    all_extracted_flags.append({
        "team": team_id, "challenge": "hidden_web",
        "flag": web_decoded,
        "points": POINTS["hidden_web"]
    })
    # XOR decrypt HMAC flag (XOR 5)
    hmac_raw = get_flag_from_container(files_container, "/var/www/html/secret/flag2")
    hmac_decrypted = "".join(chr(ord(c) ^ 5) for c in hmac_raw) if hmac_raw else ""
    all_extracted_flags.append({
        "team": team_id, "challenge": "hidden_web_hmac",
        "flag": hmac_decrypted,
        "points": POINTS["hidden_web_hmac"]
    })

    # 4. PCAP Challenge
    pcap_container = f"pcap-team{i}"
    all_extracted_flags.append({
        "team": team_id, "challenge": "pcap_http",
        "flag": get_env_from_container(pcap_container, "FLAG_HTTP"),
        "points": POINTS["pcap_http"]
    })
    all_extracted_flags.append({
        "team": team_id, "challenge": "pcap_dns",
        "flag": get_env_from_container(pcap_container, "FLAG_DNS"),
        "points": POINTS["pcap_dns"]
    })

    # 5. Misconfig Challenge
    misc_container = f"misconfig-team{i}"
    all_extracted_flags.append({
        "team": team_id, "challenge": "redis_noauth",
        "flag": get_env_from_container(misc_container, "FLAG_REDIS"),
        "points": POINTS["redis_noauth"]
    })
    all_extracted_flags.append({
        "team": team_id, "challenge": "memcached",
        "flag": get_env_from_container(misc_container, "FLAG_MEMCACHED"),
        "points": POINTS["memcached"]
    })

# Cleanup: Filter out empty entries
all_extracted_flags = [f for f in all_extracted_flags if f['flag'] and "FEIT{" in f['flag'] or len(f['flag']) > 32]

# Update DB and JSON
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
db_path = os.path.join(SCRIPT_DIR, 'docker', 'scoreboard', 'data', 'ctf.db')
json_path = os.path.join(SCRIPT_DIR, 'docker', 'scoreboard', 'data', 'flags.json')

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

for f in all_extracted_flags:
    cursor.execute("UPDATE flags SET flag_value = ?, points = ? WHERE team_owner = ? AND challenge = ?", 
                  (f['flag'], f['points'], f['team'], f['challenge']))

conn.commit()
conn.close()

with open(json_path, 'w') as f:
    json.dump({"flags": all_extracted_flags}, f, indent=2)

print(f"Successfully synchronized {len(all_extracted_flags)} live flags to the scoreboard.")
