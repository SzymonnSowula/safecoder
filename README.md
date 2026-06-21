# 🛡️ SafeCoder

> Security guardrails for AI coding agents. Stop shipping apps with API keys in the frontend, missing rate limits, open signup spam, SQL injection, and prompt injection.

AI agents ship **working** apps, not **safe** ones. SafeCoder turns every build into a structured security review — rate limiting, email verification, secret management, XSS/CSRF/CSP hardening, SQL/command/path injection prevention, prompt injection defense, authorization, secure CI/CD, and more.

Built for **Claude Code**, **Codex**, **OpenCode**, **Hermes Agent**, and any coding agent that reads markdown instructions.

---

## What it protects against

| Risk | Why it matters | Default guardrail |
|------|---------------|-------------------|
| No rate limiting | Spam signups, contact-form abuse, brute force | IP-based rate limits by default |
| No email verification | Anyone can register with someone else's email | Require verified email before account is active |
| API keys in frontend | Inspect Element → free access to your Firebase/Supabase/OpenAI keys | Keys live on the backend only |
| XSS | User input rendered as code | Output encoding, CSP, sanitized HTML |
| Prompt injection | LLM ignores system instructions via user input | Instruction boundaries, allow-lists, output validation |
| SQL injection | Database theft, data loss | Parameterized queries / ORM |
| Command injection | Server compromise | No user input in shell commands |
| Path traversal | Unauthorized file access | Validate paths, random file IDs |
| Insecure file uploads | Malware, RCE | Allow-list MIME/types, size limits, sandbox |
| Missing authz | Users accessing each other's data | Resource-level ownership checks |
| Insecure headers | Clickjacking, MIME sniffing, referrer leaks | Security headers by default |
| Bad CORS | Cross-site authenticated requests | Exact-origin allow-list |
| Leaked secrets in git | Keys exposed forever | Pre-commit hooks + `.env.example` pattern |
| Insecure CI/CD | Secrets in workflows, unreviewed deploys | Secret manager + branch protection |

---

## Quick start

### Hermes Agent — one-line install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/SzymonnSowula/safecoder/main/install.sh)
```

Lub przez npm:

```bash
npx @szymonsdev/safecoder install
```

To dodaje skill i aliasy:

```bash
hermes-web   # hermes -s safecoder
hermes-app   # hermes -s safecoder
hermes-api   # hermes -s safecoder
```

Start a new terminal, then run `hermes-web` before building any web project.

### Vercel Skills / open agent skills

SafeCoder jest kompatybilny z `npx skills`:

```bash
npx skills add SzymonnSowula/safecoder@safecoder
```

### Initialize a project

```bash
npx @szymonsdev/safecoder init
```

Tworzy w projekcie:

- `AGENT_SECURITY.md`
- `.env.example`
- `scripts/security-audit.sh`
- `SECURITY.md`
- `.github/workflows/security-audit.yml` (jeśli istnieje `.github/workflows`)

### Use with Claude Code / Codex / OpenCode

Copy `skills/safecoder/SKILL.md` into your project as `AGENT_SECURITY.md` and tell the agent:

> "Follow the security requirements in AGENT_SECURITY.md for every feature you build."

Or paste the short prompt from `skills/safecoder/templates/PROMPT.md` into context.

---

## What's inside

```
safecoder/
├── README.md
├── LICENSE
├── package.json                       # npm package + CLI
├── install.sh                         # One-line installer for Hermes
├── init-project.sh                    # Adds SafeCoder files to a project
├── bin/
│   └── cli.js                            # npx @szymonsdev/safecoder install / init
├── scripts/
│   └── sync-vercel-skill.sh            # Syncs skill layout for Vercel Skills
├── .github/workflows/security-audit.yml  # CI workflow
├── skills/safecoder/                     # Vercel Skills layout
│   ├── SKILL.md
│   ├── references/
│   ├── templates/
│   └── scripts/
└── skills/software-development/safecoder/  # Hermes skill layout
    ├── SKILL.md
    ├── references/
    │   ├── security-checklist.md
    │   ├── rate-limiting-patterns.md
    │   ├── xss-prevention.md
    │   ├── prompt-injection-defense.md
    │   ├── auth-patterns.md
    │   ├── jwt-oauth2-patterns.md
    │   ├── file-upload-security.md
    │   ├── cors-guide.md
    │   ├── logging-monitoring.md
    │   ├── ci-cd-security.md
    │   ├── api-design-security.md
    │   └── owasp-top-10-for-ai-apps.md
    ├── templates/
    │   ├── env.example
    │   ├── security-config.yaml
    │   ├── security-decision-record.md
    │   ├── SECURITY.md
    │   └── PROMPT.md
    └── scripts/
        └── security-audit.sh
```

---

## Pre-ship security checklist

Every project that uses this skill must pass these checks before merge:

- [ ] Rate limits exist on auth, signup, contact, password-reset, and API endpoints
- [ ] Rate limits are enforced by IP (not just email) with user fallback for authenticated routes
- [ ] Email verification is required before the account can perform privileged actions
- [ ] No API keys, database URLs, or private tokens exist in frontend bundles
- [ ] All secrets are read from environment variables on the backend
- [ ] User input is validated on the server, escaped on output, and sanitized if HTML is allowed
- [ ] Database queries use parameterized statements or ORM methods
- [ ] No user input reaches shell, eval, exec, or raw SQL
- [ ] File uploads use allow-list MIME/types, random IDs, and size limits
- [ ] Content Security Policy blocks inline scripts and restricts script sources
- [ ] Security headers are set (`X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, etc.)
- [ ] CORS restricts origins on authenticated endpoints (no `*`)
- [ ] LLM system prompts are isolated from user content and outputs are validated against a schema
- [ ] AI API calls are rate-limited and cost-capped
- [ ] Resource access checks confirm the logged-in user owns the requested resource
- [ ] `.env` files are in `.gitignore` and an `env.example` is committed
- [ ] Pre-commit hook or CI scans for secrets before code reaches GitHub
- [ ] Dependencies are scanned for known vulnerabilities in CI

The full version lives in [`references/security-checklist.md`](skills/software-development/safecoder/references/security-checklist.md).

---

## Example: rate limiting by IP

```python
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from fastapi import FastAPI, Request

limiter = Limiter(key_func=get_remote_address)
app = FastAPI()
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

@app.post("/auth/signup")
@limiter.limit("5/minute")
def signup(request: Request):
    ...
```

> Never rate-limit by email alone. An attacker rotates emails every request.

More patterns in [`references/rate-limiting-patterns.md`](skills/software-development/safecoder/references/rate-limiting-patterns.md).

---

## Example: keeping secrets out of the frontend

❌ **Never do this:**

```javascript
const supabase = createClient(
  "https://your-project.supabase.co",  // public URL is fine
  "eyJhbG...VCJ9..."  // NEVER put service-role key here
);
```

✅ **Do this instead:**

- Frontend gets only **anon/public** keys with RLS enabled
- Backend service-role keys stay in `SUPABASE_SERVICE_ROLE_KEY` on the server
- All privileged operations go through your API, never directly from the browser

---

## Local audit

Copy `scripts/security-audit.sh` into your project root and run:

```bash
bash scripts/security-audit.sh
```

It checks for:

- Committed `.env` files
- Missing `.gitignore` entries
- Possible secrets in source
- Backend secrets in frontend paths
- Dangerous functions (`eval`, `innerHTML`, etc.)
- SQL string formatting
- Wildcard CORS
- Dependency vulnerabilities

---

## Why this exists

AI coding agents optimize for "does it run?" not "is it safe?". SafeCoder adds a security layer to every generated feature so you don't wake up to a $5,000 OpenAI bill, a spammed database, or leaked customer data.

It is opinionated on purpose:

1. **Secure by default** — turn off protections explicitly, not accidentally.
2. **Agent-readable** — written as instructions an LLM can follow.
3. **Framework-agnostic** — works with Next.js, FastAPI, Node, Rails, Laravel, Tauri, etc.
4. **Actionable** — every rule comes with code examples and a verification step.

---

## Contributing

PRs welcome. Open an issue if you find a common AI-generated vulnerability that should be covered.

---

## Publishing to npm

1. Create an npm account at https://www.npmjs.com/signup.
2. Log in locally:
   ```bash
   npm login
   ```
3. Publish from the repo root:
   ```bash
   cd safecoder
   npm publish --access=public
   ```

After the first publish, you can also enable the GitHub Action `.github/workflows/npm-publish.yml` by adding an `NPM_TOKEN` secret to the repository settings. Then every GitHub release will auto-publish.

## License

MIT
