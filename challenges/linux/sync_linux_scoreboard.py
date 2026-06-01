import sqlite3
import json
import sys
import os

# Read arguments: sys.argv[1] is the JSON payload of flags
flags_payload = json.loads(sys.argv[1])

# Use relative paths based on script location
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
db_path = os.path.join(SCRIPT_DIR, '..', '..', 'core', 'docker', 'scoreboard', 'data', 'ctf.db')
json_path = os.path.join(SCRIPT_DIR, '..', '..', 'core', 'docker', 'scoreboard', 'data', 'flags.json')

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Load existing JSON
with open(json_path, 'r') as f:
    flags_data = json.load(f)

updated_count = 0
for team_id, flag_val in flags_payload.items():
    challenge_name = "linux_fs"
    points = 300
    
    # Check if challenge exists for team
    cursor.execute("SELECT id FROM flags WHERE team_owner = ? AND challenge = ?", (team_id, challenge_name))
    row = cursor.fetchone()
    
    if row:
        cursor.execute("UPDATE flags SET flag_value = ?, points = ? WHERE id = ?", (flag_val, points, row[0]))
    else:
        cursor.execute("INSERT INTO flags (team_owner, challenge, flag_value, points) VALUES (?, ?, ?, ?)", 
                       (team_id, challenge_name, flag_val, points))
    
    updated_count += 1
    
    # Update JSON
    found = False
    for flag_entry in flags_data['flags']:
        if flag_entry['team'] == team_id and flag_entry['challenge'] == challenge_name:
            flag_entry['flag'] = flag_val
            flag_entry['points'] = points
            found = True
            break
            
    if not found:
        flags_data['flags'].append({
            "team": team_id,
            "challenge": challenge_name,
            "flag": flag_val,
            "points": points
        })

conn.commit()
conn.close()

with open(json_path, 'w') as f:
    json.dump(flags_data, f, indent=2)

print(f"Synchronized {updated_count} Linux FS flags into the scoreboard.")
