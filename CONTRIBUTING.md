# Contributing to FEIT CTF

Thank you for your interest in contributing!

## How to Contribute
1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Ensure your changes follow the project structure (Infrastructure in `core/`, Challenges in `challenges/`).
4. Test your changes using Docker Compose.
5. Submit a Pull Request with a clear description of your changes.

## Challenge Development
If you are adding a new challenge:
- Include a `Dockerfile` and `docker-compose.yml`.
- Provide a `README.md` with challenge details and solution.
- Use environment variables for flags to maintain dynamic generation support.
