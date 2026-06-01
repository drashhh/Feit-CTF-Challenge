-- FEIT CTF Scoreboard Database Schema

CREATE TABLE IF NOT EXISTS teams (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS flags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    team_owner TEXT NOT NULL,          -- which team "owns" this flag (it's in their services)
    challenge TEXT NOT NULL,            -- challenge name (web_source, sqli_database, etc.)
    flag_value TEXT UNIQUE NOT NULL,    -- the actual flag string
    points INTEGER NOT NULL DEFAULT 100,
    description TEXT
);

CREATE TABLE IF NOT EXISTS submissions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    team_name TEXT NOT NULL,            -- team that submitted
    flag_value TEXT NOT NULL,           -- what they submitted
    flag_id INTEGER,                    -- references flags.id if valid
    points_awarded INTEGER DEFAULT 0,
    is_correct BOOLEAN DEFAULT 0,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address TEXT,
    FOREIGN KEY (flag_id) REFERENCES flags(id)
);

-- Index for fast duplicate checking
CREATE INDEX IF NOT EXISTS idx_submissions_team_flag ON submissions(team_name, flag_id);

-- Index for scoreboard queries
CREATE INDEX IF NOT EXISTS idx_submissions_correct ON submissions(is_correct, team_name);
