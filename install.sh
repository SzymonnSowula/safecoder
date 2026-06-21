#!/usr/bin/env bash
# SafeCoder skill installer for Hermes Agent
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/SzymonnSowula/safecoder/main/install.sh)
#        or: bash install.sh

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SKILL_SRC="$REPO_DIR/skills/software-development/safecoder"
SKILL_DEST="$HERMES_HOME/skills/software-development/safecoder"

if [ ! -d "$SKILL_SRC" ]; then
    echo "Error: skill source not found at $SKILL_SRC"
    exit 1
fi

mkdir -p "$HERMES_HOME/skills/software-development"
rm -rf "$SKILL_DEST"
cp -r "$SKILL_SRC" "$SKILL_DEST"

echo "SafeCoder skill installed to $SKILL_DEST"

# Add aliases to shell configs
add_alias() {
    local file="$1"
    if [ -f "$file" ]; then
        if ! grep -q "alias hermes-web='hermes -s safecoder'" "$file" 2>/dev/null; then
            echo "" >> "$file"
            echo "# SafeCoder aliases - auto-load security skill for web/app projects" >> "$file"
            echo "alias hermes-web='hermes -s safecoder'" >> "$file"
            echo "alias hermes-app='hermes -s safecoder'" >> "$file"
            echo "alias hermes-api='hermes -s safecoder'" >> "$file"
            echo "Updated $file"
        else
            echo "Aliases already present in $file"
        fi
    fi
}

add_alias "$HOME/.bashrc"
add_alias "$HOME/.zshrc"
add_alias "$HOME/.bash_aliases"

echo ""
echo "Done. Start a new terminal or run:"
echo "  source ~/.bashrc"
echo ""
echo "Then use:"
echo "  hermes-web   (hermes -s safecoder)"
echo "  hermes-app   (hermes -s safecoder)"
echo "  hermes-api   (hermes -s safecoder)"
echo ""
echo "Optional: run this in your project root to add SafeCoder files:"
echo "  bash $REPO_DIR/init-project.sh"
