#!/usr/bin/env bash
# SafeCoder quick local security audit
# Run from the root of your project.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

log_ok() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; ((WARNINGS++)) || true; }
log_error() { echo -e "${RED}[FAIL]${NC} $1"; ((ERRORS++)) || true; }
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }

echo "== SafeCoder Quick Audit =="
echo ""

# 1. .env files in git
if git ls-files 2>/dev/null | grep -qE '^\.env($|\.local|\.production|\.development)'; then
  log_error ".env file committed to git"
else
  log_ok "No real .env files in git"
fi

if git ls-files 2>/dev/null | grep -qE '^\.env\.example$'; then
  log_ok ".env.example exists"
else
  log_warn "No .env.example committed"
fi

# 2. .gitignore
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
SECRETS=$(git grep -IEn "$PATTERNS" -- '*.js' '*.ts' '*.jsx' '*.tsx' '*.py' '*.rb' '*.go' '*.java' '*.php' '*.env*' 2>/dev/null | head -20 || true)
if [ -n "$SECRETS" ]; then
  echo "$SECRETS"
  log_warn "Possible secrets or sensitive strings found (review manually)"
else
  log_ok "No obvious secret patterns in tracked source"
fi

# 4. Frontend exposure of backend keys
FRONTEND_SECRETS=$(git grep -IEn "(SUPABASE_SERVICE_ROLE_KEY|OPENAI_API_KEY|STRIPE_SECRET_KEY|DATABASE_URL|APP_SECRET|AWS_SECRET)" -- 'app/*' 'src/*' 'frontend/*' 'components/*' 'pages/*' 'public/*' 2>/dev/null | head -20 || true)
if [ -n "$FRONTEND_SECRETS" ]; then
  echo "$FRONTEND_SECRETS"
  log_error "Backend secret appears in frontend code"
else
  log_ok "No obvious backend secrets in frontend paths"
fi

# 5. Check for dangerous functions
DANGEROUS=$(git grep -IEn "(eval\(|exec\(|os\.system|subprocess\.call\(.*shell|dangerouslySetInnerHTML|innerHTML\s*=|document\.write)" -- '*.js' '*.ts' '*.jsx' '*.tsx' '*.py' '*.rb' '*.go' '*.java' '*.php' 2>/dev/null | head -20 || true)
if [ -n "$DANGEROUS" ]; then
  echo "$DANGEROUS"
  log_warn "Dangerous functions found (review manually)"
else
  log_ok "No obvious dangerous functions"
fi

# 6. Check for SQL string concatenation
SQL_RISKY=$(git grep -IEn "(f\".*SELECT|f'.*SELECT|\.format\(.*SELECT|\+.*SELECT|%s.*SELECT|execute\s*\(\s*f[\"'])" -- '*.py' '*.js' '*.ts' '*.rb' '*.php' '*.go' '*.java' 2>/dev/null | head -20 || true)
if [ -n "$SQL_RISKY" ]; then
  echo "$SQL_RISKY"
  log_warn "Possible SQL string formatting found"
else
  log_ok "No obvious SQL string formatting"
fi

# 7. Check for wildcard CORS
WILDCARD_CORS=$(git grep -IEn "Access-Control-Allow-Origin.*\*|origins.*['\"]\\*['\"]|CORS\(.*origins=\"\*\"" -- '*.py' '*.js' '*.ts' '*.go' '*.java' '*.rb' '*.php' 2>/dev/null | head -10 || true)
if [ -n "$WILDCARD_CORS" ]; then
  echo "$WILDCARD_CORS"
  log_warn "Wildcard CORS found"
else
  log_ok "No obvious wildcard CORS"
fi

# 8. Framework-specific dependency audits
echo ""
if [ -f package.json ]; then
  log_info "Node.js project detected"
  if npm audit --audit-level=high >/dev/null 2>&1; then
    log_ok "npm audit: no high/critical issues"
  else
    log_warn "npm audit found high/critical issues"
  fi
fi

if [ -f requirements.txt ] || [ -f pyproject.toml ]; then
  log_info "Python project detected"
  if command -v pip-audit >/dev/null 2>&1; then
    if pip-audit --desc --format=json >/dev/null 2>&1; then
      log_ok "pip-audit: no issues"
    else
      log_warn "pip-audit found issues"
    fi
  else
    log_warn "pip-audit not installed"
  fi
fi

if [ -f Cargo.toml ]; then
  log_info "Rust project detected"
  if command -v cargo-audit >/dev/null 2>&1; then
    if cargo audit >/dev/null 2>&1; then
      log_ok "cargo audit: no issues"
    else
      log_warn "cargo audit found issues"
    fi
  else
    log_warn "cargo-audit not installed"
  fi
fi

# 9. Summary
echo ""
echo "== Summary =="
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"

if [ "$ERRORS" -gt 0 ]; then
  exit 1
else
  exit 0
fi
