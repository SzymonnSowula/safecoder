#!/usr/bin/env bash
# Initialize SafeCoder in the current project
# Run from the root of your project.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$REPO_DIR/skills/software-development/safecoder"

if [ ! -d "$SKILL_DIR" ]; then
    echo "Error: SafeCoder skill not found at $SKILL_DIR"
    exit 1
fi

echo "Initializing SafeCoder in $(pwd)"

# Copy AGENT_SECURITY.md prompt
cp "$SKILL_DIR/templates/PROMPT.md" ./AGENT_SECURITY.md
echo "Created AGENT_SECURITY.md"

# Copy env example if .env.example doesn't exist
if [ ! -f .env.example ]; then
    cp "$SKILL_DIR/templates/env.example" ./.env.example
    echo "Created .env.example"
fi

# Copy audit script if not exists
if [ ! -f scripts/security-audit.sh ]; then
    mkdir -p scripts
    cp "$SKILL_DIR/scripts/security-audit.sh" scripts/security-audit.sh
    chmod +x scripts/security-audit.sh
    echo "Created scripts/security-audit.sh"
fi

# Copy SECURITY.md if not exists
if [ ! -f SECURITY.md ]; then
    cp "$SKILL_DIR/templates/SECURITY.md" ./SECURITY.md
    echo "Created SECURITY.md"
fi

# Copy CI workflow if .github/workflows exists
if [ -d .github/workflows ]; then
    if [ ! -f .github/workflows/security-audit.yml ]; then
        cp "$REPO_DIR/.github/workflows/security-audit.yml" .github/workflows/security-audit.yml
        echo "Created .github/workflows/security-audit.yml"
    fi
fi

# Ensure .env is in .gitignore
if [ -f .gitignore ]; then
    if ! grep -q "^\.env" .gitignore; then
        echo "" >> .gitignore
        echo ".env" >> .gitignore
        echo "Added .env to .gitignore"
    fi
else
    echo ".env" > .gitignore
    echo "Created .gitignore with .env"
fi

echo ""
echo "Done. Add this to your agent context:"
echo "  Follow the security requirements in AGENT_SECURITY.md."
