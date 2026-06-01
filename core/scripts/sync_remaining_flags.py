import os
import json
import sqlite3
import subprocess

def run_cmd(cmd):
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.stdout.strip()

live_flags = {}

print("Extracting live SQLi Flags...")
for i in range(1, 6):
    team = f"team{i}"
    # SQLi
    sqli_flag = run_cmd(f"docker exec sqli-team{i} cat /opt/flag.txt 2>/dev/null")
    if sqli_flag and "FEIT{" in sqli_flag:
        live_flags[f"{team}_sqli_database"] = sqli_flag

print("Extracting live Hidden Files Flags...")
for i in range(1, 6):
    team = f"team{i}"
    # Hidden FTP (Hex encoded)
    ftp_flag = run_cmd(f"docker exec files-team{i} cat /srv/ftp/.backup/admin_notes.txt 2>/dev/null")
    if ftp_flag:
        live_flags[f"{team}_hidden_ftp"] = ftp_flag
        
    # Hidden Web (Hex encoded)
    web_flag = run_cmd(f"docker exec files-team{i} cat /var/www/html/secret/flag1 2>/dev/null")
    if web_flag:
        live_flags[f"{team}_hidden_web"] = web_flag
        
    # Hidden Web HMAC (XOR encrypted with 5)
    hmac_cmd = f"docker exec files-team{i} python3 -c \"print(''.join(chr(ord(c) ^ 5) for c in open('/var/www/html/secret/flag2').read().strip()))\" 2>/dev/null"
    hmac_flag = run_cmd(hmac_cmd)
    if hmac_flag and "FEIT{" in hmac_flag:
        live_flags[f"{team}_hidden_web_hmac"] = hmac_flag

# Update paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
db_path = os.path.join(SCRIPT_DIR, 'docker', 'scoreboard', 'data', 'ctf.db')
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

json_path = os.path.join(SCRIPT_DIR, 'docker', 'scoreboard', 'data', 'flags.json')
with open(json_path, 'r') as f:
    flags_data = json.load(f)

updated_count = 0
for key, actual_flag in live_flags.items():
    parts = key.split('_', 1)
    team_str = parts[0]
    chal_db = parts[1]
    
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

print(f"Synchronized {updated_count} SQLi and Hidden Files actual container flags into the scoreboard.")
