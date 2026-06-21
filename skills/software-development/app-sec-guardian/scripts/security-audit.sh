#!/usr/bin/env bash
# AppSec Guardian quick local audit
# Run from the root of your project.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

log_ok() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; ((WARNINGS++)) || true; }
log_error() { echo -e "${RED}[FAIL]${NC} $1"; ((ERRORS++)) || true; }

echo "== AppSec Guardian Quick Audit =="
echo ""

# 1. Check for .env files in git
if git ls-files | grep -qE '^\.env($|\.example|\.local|\.production|\.development)'; then
  if git ls-files | grep -qE '^\.env($|\.local|\.production|\.development)'; then
    log_error ".env file committed to git (should be in .gitignore)"
  else
    log_ok ".env.example committed, no real .env files in git"
  fi
else
  log_warn "No .env files found in git; make sure .env.example exists"
fi

# 2. Check .gitignore
if [ -f .gitignore ]; then
  if grep -qE '^\.env' .gitignore; then
    log_ok ".env is in .gitignore"
  else
    log_error ".env is NOT in .gitignore"
  fi
else
  log_warn "No .gitignore found"
fi

# 3. Scan for common secrets in source
PATTERNS='(api[_-]?key|secret[_-]?key|password|token|private[_-]?key|sk-[a-zA-Z0-9]{20,}|eyJ[A-Za-z0-9_-]*\.eyJ[A-Za-z0-9_-]*|[A-Za-z0-9_-]{32,}_[A-Za-z0-9_-]+)'
if git grep -IEn "$PATTERNS" -- '*.js' '*.ts' '*.jsx' '*.tsx' '*.py' '*.rb' '*.go' '*.java' '*.php' '*.env*' 2>/dev/null | head -20; then
  log_warn "Possible secrets or sensitive strings found in source (review manually)"
else
  log_ok "No obvious secret patterns in tracked source files"
fi

# 4. Check for frontend exposure of common backend keys
if git grep -IEn "(SUPABASE_SERVICE_ROLE_KEY|OPENAI_API_KEY|STRIPE_SECRET_KEY|DATABASE_URL|APP_SECRET)" -- 'app/*' 'src/*' 'frontend/*' 'components/*' 'pages/*' 2>/dev/null | head -20; then
  log_error "Backend secret appears to be referenced in frontend code"
else
  log_ok "No obvious backend secrets in frontend paths"
fi

# 5. Framework-specific checks
if [ -f package.json ]; then
  echo ""
  echo "-- Node.js checks --"
  if npm audit --audit-level=high >/dev/null 2>&1; then
    log_ok "npm audit: no high/critical issues"
  else
    log_warn "npm audit found high/critical issues (run 'npm audit' for details)"
  fi
fi

if [ -f requirements.txt ] || [ -f pyproject.toml ]; then
  echo ""
  echo "-- Python checks --"
  if command -v pip-audit >/dev/null 2>&1; then
    if pip-audit --desc --format=json >/dev/null 2>&1; then
      log_ok "pip-audit: no issues"
    else
      log_warn "pip-audit found issues"
    fi
  else
    log_warn "pip-audit not installed; run: pip install pip-audit"
  fi
fi

# 6. Summary
echo ""
echo "== Summary =="
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"

if [ "$ERRORS" -gt 0 ]; then
  exit 1
else
  exit 0
fi
