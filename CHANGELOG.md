# Changelog

## [1.1.0] - 2026-06-01

### 🛡️ Security
- **Full Secret Sanitization**: Removed all hardcoded flags, VPN private keys, and administrative passwords from the repository.
- **Environment Templates**: Replaced live `.env` and `.ovpn` files with `.example` templates.
- **Dockerfile Hardening**: Replaced hardcoded passwords in the Linux challenge with Docker build arguments.
- **Improved .gitignore**: Added comprehensive rules to prevent accidental leaks of flags and session data.
- **Modular Challenges**: Refactored challenges to be standalone and modular, simplifying future additions.
- **Consolidation**: Removed redundant challenge definitions and duplicate scripts.

### 🐧 Linux Compatibility
- **Line Ending Standardization**: Converted all scripts and configurations to LF (Unix) line endings.
- **Relative Pathing**: Updated all shell and Python scripts to use dynamic project root detection instead of hardcoded `/opt/feit-ctf`.
- **Git Attributes**: Added `.gitattributes` to enforce line ending consistency across platforms.

### 📄 Documentation
- **New Project Documentation**: Added `README.md`, `LICENSE` (MIT), `CONTRIBUTING.md`, and `SECURITY.md`.
- **Updated Setup Guide**: Updated the master `setup_all.sh` to support the new modular architecture.

## [1.0.0] - Initial Backup Version
- Raw backup from the FEIT CTF production server.
- Contained live secrets and hardcoded system paths.
