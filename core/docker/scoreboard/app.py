"""
FEIT CTF Scoreboard Application
Flask-based flag submission and scoring system.
"""

import os
import sqlite3
import json
import hashlib
import logging
from datetime import datetime, timedelta
from functools import wraps
from flask import Flask, render_template, request, redirect, url_for, session, flash, jsonify

app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'change_me_in_production')
app.permanent_session_lifetime = timedelta(days=30)

DB_PATH = '/app/data/ctf.db'
LOG_PATH = '/app/data/submissions.log'
FLAGS_PATH = '/app/data/flags.json'

logging.basicConfig(
    filename=LOG_PATH,
    level=logging.INFO,
    format='%(asctime)s - %(message)s'
)


def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    """Initialize database from schema."""
    conn = get_db()
    with open('/app/schema.sql', 'r') as f:
        conn.executescript(f.read())

    # Create default teams if they don't exist
    teams = ['M3', 'team2', 'team3', 'team4', 'Demure Hakerz']
    for team in teams:
        pw_hash = hashlib.sha256(f'{team}_password'.encode()).hexdigest()
        try:
            conn.execute(
                'INSERT INTO teams (name, password_hash) VALUES (?, ?)',
                (team, pw_hash)
            )
        except sqlite3.IntegrityError:
            pass

    # Load flags from JSON if available
    if os.path.exists(FLAGS_PATH):
        with open(FLAGS_PATH, 'r') as f:
            data = json.load(f)
        for flag_entry in data.get('flags', []):
            try:
                conn.execute(
                    'INSERT INTO flags (team_owner, challenge, flag_value, points) VALUES (?, ?, ?, ?)',
                    (flag_entry['team'], flag_entry['challenge'],
                     flag_entry['flag'], flag_entry['points'])
                )
            except sqlite3.IntegrityError:
                pass

    conn.commit()
    conn.close()


def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'team' not in session:
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated


def admin_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if session.get('team') != 'admin':
            flash('Admin access required.', 'error')
            return redirect(url_for('scoreboard'))
        return f(*args, **kwargs)
    return decorated


@app.route('/')
def index():
    return redirect(url_for('scoreboard'))


@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        team = request.form.get('team', '').strip()
        password = request.form.get('password', '').strip()

        # Admin login
        admin_pw = os.environ.get('ADMIN_PASSWORD', 'admin_ctf_2024')
        if team == 'admin' and password == admin_pw:
            session.permanent = True
            session['team'] = 'admin'
            return redirect(url_for('admin_panel'))

        # Team login
        conn = get_db()
        pw_hash = hashlib.sha256(password.encode()).hexdigest()
        row = conn.execute(
            'SELECT * FROM teams WHERE name = ? AND password_hash = ?',
            (team, pw_hash)
        ).fetchone()
        conn.close()

        if row:
            session.permanent = True
            session['team'] = team
            return redirect(url_for('submit_flag'))
        else:
            flash('Invalid team name or password.', 'error')

    return render_template('login.html')


@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))


@app.route('/submit', methods=['GET', 'POST'])
@login_required
def submit_flag():
    message = None
    if request.method == 'POST':
        flag_value = request.form.get('flag', '').strip()
        team = session['team']
        ip = request.remote_addr

        if not flag_value:
            flash('Please enter a flag.', 'error')
        else:
            conn = get_db()

            # Check if flag exists
            flag_row = conn.execute(
                'SELECT * FROM flags WHERE flag_value = ?', (flag_value,)
            ).fetchone()

            if not flag_row:
                # Invalid flag
                conn.execute(
                    'INSERT INTO submissions (team_name, flag_value, is_correct, ip_address) VALUES (?, ?, 0, ?)',
                    (team, flag_value, ip)
                )
                conn.commit()
                flash('Incorrect flag!', 'error')
                logging.info(f'INCORRECT: team={team} flag={flag_value} ip={ip}')
            elif flag_row['team_owner'] == team:
                # Team submitted their own flag
                flash('You cannot submit your own flag!', 'error')
                logging.info(f'OWN_FLAG: team={team} flag={flag_value} ip={ip}')
            else:
                # Check if they already submitted this exact flag
                existing = conn.execute(
                    'SELECT id FROM submissions WHERE team_name = ? AND flag_id = ? AND is_correct = 1',
                    (team, flag_row['id'])
                ).fetchone()

                if existing:
                    flash('You already submitted this flag!', 'warning')
                    logging.info(f'DUPLICATE: team={team} flag={flag_value} ip={ip}')
                else:
                    # Valid new submission
                    conn.execute(
                        'INSERT INTO submissions (team_name, flag_value, flag_id, points_awarded, is_correct, ip_address) VALUES (?, ?, ?, ?, 1, ?)',
                        (team, flag_value, flag_row['id'], flag_row['points'], ip)
                    )
                    conn.commit()
                    flash(f'Correct! +{flag_row["points"]} points!', 'success')
                    logging.info(f'CORRECT: team={team} flag={flag_value} points={flag_row["points"]} ip={ip}')

            conn.close()

    conn = get_db()
    solved = conn.execute('''
        SELECT f.challenge FROM submissions s
        JOIN flags f ON s.flag_id = f.id
        WHERE s.team_name = ? AND s.is_correct = 1
    ''', (session['team'],)).fetchall()
    solved_challenges = [row['challenge'] for row in solved]
    conn.close()

    return render_template('submit.html', team=session['team'], solved_challenges=solved_challenges)


@app.route('/scoreboard')
def scoreboard():
    conn = get_db()
    scores = conn.execute('''
        SELECT team_name, SUM(points_awarded) as total_points, COUNT(*) as flags_captured
        FROM submissions
        WHERE is_correct = 1
        GROUP BY team_name
        ORDER BY total_points DESC
    ''').fetchall()

    recent = conn.execute('''
        SELECT team_name, points_awarded, submitted_at
        FROM submissions
        WHERE is_correct = 1
        ORDER BY submitted_at DESC
        LIMIT 10
    ''').fetchall()

    conn.close()
    return render_template('scoreboard.html', scores=scores, recent=recent)


@app.route('/admin')
@login_required
@admin_required
def admin_panel():
    conn = get_db()
    all_submissions = conn.execute('''
        SELECT s.*, f.challenge, f.team_owner
        FROM submissions s
        LEFT JOIN flags f ON s.flag_id = f.id
        ORDER BY s.submitted_at DESC
        LIMIT 50
    ''').fetchall()

    flags = conn.execute('SELECT * FROM flags ORDER BY team_owner, challenge').fetchall()
    conn.close()
    return render_template('admin.html', submissions=all_submissions, flags=flags)


@app.route('/api/scores')
def api_scores():
    """JSON endpoint for live scoreboard updates."""
    conn = get_db()
    scores = conn.execute('''
        SELECT team_name, SUM(points_awarded) as total_points, COUNT(*) as flags_captured
        FROM submissions
        WHERE is_correct = 1
        GROUP BY team_name
        ORDER BY total_points DESC
    ''').fetchall()
    conn.close()
    return jsonify([dict(row) for row in scores])


if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000, debug=False)
