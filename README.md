# 🛡️ SafeCoder

> Security guardrails for AI coding agents. Stop shipping apps with API keys in the frontend, missing rate limits, and open signup spam.

AI agents ship **working** apps, not **safe** ones. This skill turns every build into a security review by default — rate limiting, email verification, secret management, XSS hardening, prompt injection defense, and more.

Built for **Claude Code**, **Codex**, **OpenCode**, **Hermes Agent**, and any other coding agent that reads markdown instructions.

---

## What it protects against

| Risk | Why it matters | Default guardrail |
|------|---------------|-------------------|
| No rate limiting | Spam signups, contact-form abuse, brute force | IP-based rate limits by default |
| No email verification | Anyone can register with someone else's email | Require verified email before account is active |
| API keys in frontend | Inspect Element → free access to your Firebase/Supabase/OpenAI keys | Keys live on the backend only |
| XSS | User input rendered as code | Output encoding, CSP, sanitized HTML |
| Prompt injection | LLM ignores system instructions via user input | Instruction boundaries, allow-lists, output validation |
| Secrets in git | Leaked `.env` files in commits | Pre-commit hooks + `.env.example` pattern |
| Missing authz | Authenticated users accessing each other's data | Resource-level authorization checks |
| Insecure headers | Clickjacking, MIME sniffing, referrer leaks | Security headers by default |

---

## Quick start

### Use with Hermes Agent

```bash
# Clone this repo
git clone https://github.com/SzymonnSowula/safecoder.git

# Copy the skill into your Hermes skills directory
cp -r safecoder/skills/software-development/safecoder \
  ~/.hermes/skills/software-development/

# Use it in any session
# "Apply SafeCoder to this project before we finish."
```

### Use with Claude Code / Codex / OpenCode

Copy `skills/software-development/safecoder/SKILL.md` into your project as `AGENT_SECURITY.md` (or paste it into context) and tell the agent:

> "Follow the security requirements in AGENT_SECURITY.md for every feature you build."

---

## What's inside

```
safecoder/
├── README.md
└── skills/software-development/safecoder/
    ├── SKILL.md                         # Main agent instructions
    ├── references/
    │   ├── security-checklist.md        # Pre-ship checklist
    │   ├── rate-limiting-patterns.md    # IP / user / endpoint rules
    │   ├── xss-prevention.md            # Output encoding + CSP guide
    │   ├── prompt-injection-defense.md  # LLM input/output hardening
    │   └── auth-patterns.md             # Email verify, sessions, authz
    ├── templates/
    │   ├── env.example                  # Safe environment template
    │   └── security-config.yaml         # Example rate-limit / CSP config
    └── scripts/
        └── security-audit.sh            # Fast local audit script
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
- [ ] Content Security Policy blocks inline scripts and restricts script sources
- [ ] Security headers are set (`X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, etc.)
- [ ] LLM system prompts are isolated from user content and outputs are validated against a schema
- [ ] Resource access checks confirm the logged-in user owns the requested resource
- [ ] `.env` files are in `.gitignore` and an `env.example` is committed
- [ ] Pre-commit hook or CI scans for secrets before code reaches GitHub

The full version lives in [`references/security-checklist.md`](skills/software-development/safecoder/references/security-checklist.md).

---

## Example: rate limiting by IP

```python
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from fastapi import FastAPI

limiter = Limiter(key_func=get_remote_address)
app = FastAPI()
app.state.limiter = limiter

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
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."  // NEVER put service-role key here
);
```

✅ **Do this instead:**

- Frontend gets only **anon/public** keys with RLS enabled
- Backend service-role keys stay in `SUPABASE_SERVICE_ROLE_KEY` on the server
- All privileged operations go through your API, never directly from the browser

---

## Why this exists

AI coding agents optimize for "does it run?" not "is it safe?". This skill adds a security layer to every generated feature so you don't wake up to a $5,000 OpenAI bill or a spammed database.

It is opinionated on purpose:

1. **Secure by default** — turn off protections explicitly, not accidentally.
2. **Agent-readable** — written as instructions an LLM can follow.
3. **Framework-agnostic** — works with Next.js, FastAPI, Node, Rails, Laravel, Tauri, etc.

---

## Contributing

PRs welcome. Open an issue if you find a common AI-generated vulnerability that should be covered.

---

## License

MIT
