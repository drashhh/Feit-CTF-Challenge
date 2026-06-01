import json
import sqlite3
import os

# Use relative paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
live_flags_file = os.path.join(SCRIPT_DIR, 'live_flags.txt')

# Read live extracted flags
live_flags = {}
if os.path.exists(live_flags_file):
    with open(live_flags_file, 'r') as f:
        for line in f:
            line = line.strip()
            if '=' in line and line.startswith('TEAM'):
                key, val = line.split('=', 1)
                if val:
                    live_flags[key] = val

# Mapping to database challenge names
chal_map = {
    "WEB_SOURCE": "web_source",
    "WEB_HEADER": "web_header",
    "SQLI": "sqli_database",
    "HIDDEN_FTP": "hidden_ftp",
    "HIDDEN_WEB": "hidden_web",
    "HIDDEN_WEB_HMAC": "hidden_web_hmac",
    "PCAP_HTTP": "pcap_http",
    "PCAP_DNS": "pcap_dns",
    "REDIS": "redis_noauth",
    "MEMCACHED": "memcached"
}

db_path = os.path.join(SCRIPT_DIR, 'docker', 'scoreboard', 'data', 'ctf.db')
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# We only update the DB and JSON for flags we actually extracted from the containers
json_path = os.path.join(SCRIPT_DIR, 'docker', 'scoreboard', 'data', 'flags.json')
with open(json_path, 'r') as f:
    flags_data = json.load(f)

updated_count = 0
for env_key, actual_flag in live_flags.items():
    # Parse env_key like TEAM1_WEB_SOURCE
    parts = env_key.split('_', 1)
    team_str = parts[0].lower() # team1
    chal_raw = parts[1] # WEB_SOURCE
    chal_db = chal_map.get(chal_raw)
    
    if chal_db:
        # Update Database
        cursor.execute("UPDATE flags SET flag_value = ? WHERE team_owner = ? AND challenge = ?", 
                      (actual_flag, team_str, chal_db))
        if cursor.rowcount > 0:
            updated_count += 1
            
        # Update JSON
        for flag_entry in flags_data['flags']:
            if flag_entry['team'] == team_str and flag_entry['challenge'] == chal_db:
                flag_entry['flag'] = actual_flag

conn.commit()
conn.close()

with open(json_path, 'w') as f:
    json.dump(flags_data, f, indent=2)

print(f"Synchronized {updated_count} actual container flags into the scoreboard.")
