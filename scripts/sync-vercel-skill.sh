#!/usr/bin/env bash
# Sync Hermes-format skill into Vercel Skills-compatible layout
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO_DIR/skills/software-development/safecoder"
DST="$REPO_DIR/skills/safecoder"

rm -rf "$DST"
mkdir -p "$DST"
cp -r "$SRC"/* "$DST/"

echo "Synced Vercel Skills layout: $DST"
