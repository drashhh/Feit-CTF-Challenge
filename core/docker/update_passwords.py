import sqlite3
import hashlib
import random
import string

def generate_password(length=12):
    characters = string.ascii_letters + string.digits
    return ''.join(random.choice(characters) for i in range(length))

import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
db_path = os.path.join(SCRIPT_DIR, 'scoreboard', 'data', 'ctf.db')
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

teams = ['team1', 'team2', 'team3', 'team4', 'team5']
passwords = {}

for team in teams:
    new_password = generate_password()
    passwords[team] = new_password
    pw_hash = hashlib.sha256(new_password.encode()).hexdigest()
    cursor.execute("UPDATE teams SET password_hash = ? WHERE name = ?", (pw_hash, team))

conn.commit()
conn.close()

for team, pwd in passwords.items():
    print(f"{team}: {pwd}")
