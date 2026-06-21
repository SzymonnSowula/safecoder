---
name: safecoder
description: "Use when an AI coding agent is building or reviewing a web app, API, or desktop app and you want security guardrails applied by default: rate limiting, email verification, secret handling, XSS/CSRF/CSP hardening, prompt injection defense, SQL/command/path injection defense, authorization, and secure CI/CD."
version: 2.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [security, ai-agents, web-apps, apis, authentication, rate-limiting, xss, prompt-injection, sql-injection, supply-chain, ci-cd-security]
    related_skills: [requesting-code-review, systematic-debugging, nextjs-development, plan]
---

# SafeCoder

Apply security-by-default to every feature an AI coding agent builds. This skill forces a structured security review before any feature is considered done.

AI agents ship **working** apps, not **safe** ones. SafeCoder turns every build into a security review.

## What This Skill Gives the Agent

1. A repeatable workflow to apply to every feature.
2. Concrete code patterns for common frameworks.
3. A pre-ship checklist that must pass before merge.
4. A local audit script to catch obvious mistakes.
5. Templates for env files, security configs, and project SECURITY.md.

## When to Use

Use this skill whenever you:

- Start a new project or feature.
- Build or review auth flows (signup, login, password reset, email verification).
- Add public-facing forms or API endpoints.
- Integrate third-party services (Firebase, Supabase, OpenAI, Stripe, etc.).
- Render user-generated content or pass user input to an LLM.
- Add file uploads, webhooks, websockets, or background jobs.
- Perform a final pre-merge or pre-ship security audit.

Do not use this skill as a replacement for a full penetration test or formal security audit.

## How to Use This Skill

For every feature you build, run this loop:

1. **Read the threat model.** Ask: what can an unauthenticated user, authenticated user, or admin do that they shouldn't?
2. **Apply the relevant Core Security Rules below.** Not every rule applies to every feature; apply the ones that do.
3. **Use the One-Shot Recipes** for common tasks.
4. **Run the local audit script** (`scripts/security-audit.sh` from this skill, or copy it into the target project).
5. **Check the Verification Checklist** at the end of this skill before declaring the feature done.
6. **If you skip a rule, document why** in a Security Decision Record (SDR) using the template in `templates/security-decision-record.md`.

Default stance: **secure first, relax only with explicit user approval.**

## Installing and Auto-Loading This Skill

### For Hermes Agent users

Use the installer:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/SzymonnSowula/safecoder/main/install.sh)
```

It copies the skill into `~/.hermes/skills/software-development/safecoder/` and adds aliases:

- `hermes-web`
- `hermes-app`
- `hermes-api`

Each alias runs `hermes -s safecoder`. Use them whenever you start a web/app/API project.

To add SafeCoder files to a project:

```bash
bash /path/to/safecoder/init-project.sh
```

### For other agents (Claude Code / Codex / OpenCode)

Copy `templates/PROMPT.md` into your project as `AGENT_SECURITY.md` and load it into context.

## Core Security Rules

### 1. Rate Limiting

Every public endpoint that triggers email, writes to the database, authenticates, or calls an external API must be rate-limited.

- Limit by **IP address** first. Email-only limits are useless.
- For authenticated routes, combine IP + user ID.
- Recommended defaults:
  - Signup, login, password reset: 5 per 5 minutes per IP.
  - Contact forms: 3 per hour per IP.
  - Generic API reads: 100 per minute per IP.
  - AI / expensive operations: 10 per minute per user.
- Return `429 Too Many Requests` with a `Retry-After` header.
- Use Redis or a database in production; in-memory stores reset on restart.

See `references/rate-limiting-patterns.md` for FastAPI, Express, Next.js, and Nginx examples.

### 2. Email Verification

Signup is not complete until the email is verified.

- Send a one-time link or code to the registered email.
- Tokens must be random, single-use, and expire (e.g., 1 hour).
- Do not expose whether an email is already registered.
- Restrict privileged actions until verification is complete.

### 3. Secrets Stay on the Backend

No API keys, service-role keys, database URLs, or private tokens in frontend code.

- Frontend gets only public/anon keys with RLS enabled.
- Privileged operations go through your backend API.
- Read secrets from environment variables; never hard-code them.
- Commit `.env.example`; put `.env` in `.gitignore`.
- Scan commits with `gitleaks`, `trufflehog`, or a pre-commit hook.

Bad:

```javascript
const supabase = createClient(url, "eyJ...service-role-key...");
```

Good:

```javascript
// frontend
const supabase = createClient(publicUrl, anonKey); // RLS enforced
```

```python
# backend
import os
openai_key = os.environ["OPENAI_API_KEY"]
```

### 4. XSS Prevention

Treat every byte of user input as untrusted.

- Validate input server-side (type, length, allowed characters).
- Escape output in the correct context (HTML, JS, CSS, URL, JSON).
- Sanitize rich HTML server-side with an allow-list.
- Use a strict CSP.
- Set `X-Content-Type-Options: nosniff`.

See `references/xss-prevention.md`.

### 5. CSRF Protection

- Use SameSite cookies (`Lax` or `Strict`).
- Require CSRF tokens for cookie-based session forms.
- Prefer Authorization bearer tokens for SPAs/APIs.
- Validate `Origin` / `Referer` for sensitive actions.

### 6. Secure Headers

Add these headers to every response:

```
Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=(), camera=()
Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
```

### 7. Prompt Injection Defense

When user input goes to an LLM:

- Separate system instructions from user content with delimiters.
- Treat LLM output as untrusted; validate against a schema.
- Never let LLM output reach `eval`, `exec`, SQL, shell, or file paths unsupervised.
- Escape raw LLM output before rendering.

See `references/prompt-injection-defense.md`.

### 8. Authorization on Every Resource Access

Authentication is not authorization.

- Verify ownership or permission for every resource read/modify.
- Never trust IDs from URL/body without checking.
- Use row-level security where available.

Bad:

```python
def get_order(order_id):
    return db.orders.find_one({"_id": order_id})
```

Good:

```python
def get_order(user_id, order_id):
    return db.orders.find_one({"_id": order_id, "user_id": user_id})
```

### 9. Passwords and Sessions

- Hash passwords with Argon2id, bcrypt, or scrypt.
- Use cryptographically random session IDs.
- Set `HttpOnly`, `Secure`, `SameSite=Strict` cookies.
- Rotate session IDs on login and password change; invalidate on logout.

### 10. SQL Injection Prevention

Never concatenate user input into SQL.

- Use parameterized queries / prepared statements.
- Use ORM methods, not raw SQL strings.
- Validate and allow-list sort/filter columns.

Bad:

```python
cursor.execute(f"SELECT * FROM users WHERE email = '{email}'")
```

Good:

```python
cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
```

### 11. Command Injection Prevention

Never pass user input to shell commands.

- Use language-native libraries instead of shelling out.
- If shell is unavoidable, use a strict allow-list and `subprocess` with a list of args.
- Never use `os.system`, `eval`, or `exec` with user data.

Bad:

```python
os.system(f"convert {user_path} output.jpg")
```

Good:

```python
import subprocess
subprocess.run(["convert", user_path, "output.jpg"], check=True)
```

### 12. Path Traversal Prevention

Never let user input construct file paths.

- Use an allow-list of allowed files or IDs.
- Resolve paths and verify they stay inside a base directory.
- Store user files under IDs, not original filenames.

Bad:

```python
send_file(f"/uploads/{user_id}/{filename}")
```

Good:

```python
from pathlib import Path
base = Path("/uploads") / str(user_id)
file_path = (base / filename).resolve()
if not str(file_path).startswith(str(base.resolve())):
    raise Forbidden()
```

### 13. File Upload Security

- Allow-list extensions and MIME types.
- Verify file content, not just extension.
- Limit file size.
- Store uploads outside the web root; serve via controller or signed URLs.
- Scan with antivirus or sandbox if handling untrusted files.
- Rename files to random IDs; never trust original filename.

See `references/file-upload-security.md`.

### 14. CORS

- Never use `Access-Control-Allow-Origin: *` on authenticated endpoints.
- Specify exact allowed origins in config.
- Limit allowed methods and headers.
- Do not reflect the `Origin` header blindly.

See `references/cors-guide.md`.

### 15. Logging and Monitoring

- Log authentication events, password resets, privilege changes, and access denials.
- Never log passwords, tokens, full credit card numbers, or raw PII.
- Hash or tokenize user IDs in logs when possible.
- Set alerts for brute-force patterns and anomalous activity.

See `references/logging-monitoring.md`.

### 16. JWT and OAuth2

If using JWT:

- Use strong signing algorithms (`RS256`, `ES256`). Never `none` or `HS256` with weak secrets.
- Keep expiry short (minutes, not days).
- Store tokens in `HttpOnly` cookies or secure storage, never localStorage for sensitive tokens.
- Validate `iss`, `aud`, `exp`, `nbf` claims.

If using OAuth2:

- Use PKCE for mobile/SPA flows.
- Validate state parameter.
- Store client secrets server-side only.

See `references/jwt-oauth2-patterns.md`.

### 17. WebSocket Security

- Authenticate the WebSocket handshake, not just the initial HTTP request.
- Reject unauthenticated connections.
- Rate-limit messages per connection.
- Validate every incoming message schema.
- Do not broadcast sensitive data to all connected clients.

### 18. Webhook Security

- Verify signatures using a shared secret.
- Use idempotency keys to avoid duplicate processing.
- Rate-limit webhook receivers.
- Validate event types against an allow-list.
- Return quickly; process asynchronously.

### 19. AI API Cost Control

- Cap monthly/daily spend in the provider dashboard.
- Track token usage per user.
- Validate and sanitize input before sending to the AI API.
- Cache common responses.
- Add per-user rate limits.

### 20. Markdown Rendering

Markdown from users is XSS waiting to happen.

- Use a strict markdown parser with HTML disabled, or sanitize aggressively.
- Disable raw HTML by default.
- Add `rel="nofollow noopener"` to links.
- Escape raw HTML output before rendering.

### 21. Dependencies and Supply Chain

- Pin versions and commit lockfiles.
- Run `npm audit`, `pip-audit`, `cargo audit`, etc. in CI.
- Review new dependencies before adding them.
- Use private registry or namespace packages where applicable.

### 22. CI/CD Security

- Do not store secrets in workflow files.
- Use GitHub/GitLab secret managers.
- Require approval for deployments from external contributors.
- Run security scans in CI before merge.
- Use least-privilege tokens for deployment.

See `references/ci-cd-security.md`.

## Common Pitfalls

1. **Rate limiting by email only.** Attackers rotate emails infinitely. Use IP first.
2. **Trusting frontend validation.** Always re-validate on the server.
3. **Service-role keys in the client.** Supabase/Firebase make this easy. Use RLS, keep service keys server-side.
4. **Raw LLM output in `eval` / SQL / shell.** Validate and parameterize.
5. **Missing ownership checks.** A logged-in user can still access another user's data.
6. **Concatenating strings into SQL.** Use parameterized queries.
7. **Trusting file extensions.** Verify MIME type and content.
8. **Committing `.env` files.** Git history remembers forever.
9. **`Access-Control-Allow-Origin: *` on authenticated routes.** Specify exact origins.
10. **Logging secrets or PII.** Review what goes into logs and error messages.
11. **Long-lived JWTs.** Short expiry + refresh rotation.
12. **No rate limits on AI features.** Burn budget fast; cap and alert.

## One-Shot Recipes

### Add Signup + Email Verification

1. Create user with `email_verified = false` and hashed password.
2. Generate random token; store hash with 1-hour expiry.
3. Send email with verification link.
4. On link click, verify hash and set `email_verified = true`.
5. Block login or privileged actions until verified.
6. Add rate limiting: 5 signup / 3 resend per 5 minutes per IP.

### Integrate a Third-Party API

1. Move API key to backend env var.
2. Create backend route that calls the API.
3. Add rate limiting and input validation.
4. Validate API response before returning to frontend.
5. Remove any key from frontend; rotate if exposed.

### Add File Upload

1. Allow-list MIME types and extensions.
2. Limit file size.
3. Save with random ID, not original filename.
4. Store outside web root; serve via controller.
5. Scan content if possible.

### Secure a Database Query

1. Use ORM or parameterized query.
2. Validate sort/filter columns against allow-list.
3. Add ownership filter.
4. Limit result set size.

### Add an AI Feature

1. Separate system instructions from user input.
2. Define output schema.
3. Validate LLM output against schema.
4. Rate-limit per user and cap cost.
5. Escape output before rendering.

### Harden Headers

1. Add middleware that sets CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy, HSTS.
2. Test with `curl -I`.
3. Verify CSP blocks inline scripts.

### Set Up CI Security Scanning

1. Add `scripts/security-audit.sh` to the project.
2. Run it in GitHub Actions on every PR.
3. Add dependency audit step (`npm audit`, `pip-audit`).
4. Add secret scanning (`trufflehog` or `gitleaks`).
5. Fail the build on high/critical findings.

## Security Decision Record (SDR)

If you intentionally relax a rule, write a short SDR using `templates/security-decision-record.md`. Include:

- What rule was relaxed.
- Why (threat model, user requirement).
- Compensating controls.
- Who approved it.

Never skip a rule silently.

## Verification Checklist

Before any feature or PR is considered complete:

- [ ] Rate limits exist on all public write/auth endpoints (IP-based).
- [ ] Email verification required before privileged actions.
- [ ] No secrets in frontend bundles or committed files.
- [ ] User input validated server-side and escaped on output.
- [ ] Database queries use parameterized statements or ORM.
- [ ] No user input reaches shell, eval, exec, or raw SQL.
- [ ] File uploads use allow-list MIME/types, random IDs, and size limits.
- [ ] Resource access checks ownership or permission.
- [ ] CSP and security headers configured.
- [ ] CSRF protection for cookie-based sessions.
- [ ] LLM inputs/outputs use delimiters and schema validation.
- [ ] JWT/OAuth2 uses strong algorithms, short expiry, and secure storage.
- [ ] CORS restricts origins on authenticated endpoints.
- [ ] WebSocket connections authenticate and rate-limit messages.
- [ ] Webhooks verify signatures and use idempotency keys.
- [ ] AI features have per-user rate limits and cost caps.
- [ ] Logs exclude secrets, passwords, tokens, and raw PII.
- [ ] Dependencies scanned in CI; lockfiles committed.
- [ ] CI/CD secrets stored in platform secret manager, not workflow files.
- [ ] `.env` in `.gitignore`; `.env.example` committed.
- [ ] Local security audit script passes (`scripts/security-audit.sh`).

## Links

- `references/security-checklist.md` — full pre-ship checklist
- `references/rate-limiting-patterns.md` — framework-specific rate limits
- `references/xss-prevention.md` — output encoding and CSP
- `references/prompt-injection-defense.md` — LLM hardening
- `references/auth-patterns.md` — email verify, sessions, authz
- `references/jwt-oauth2-patterns.md` — tokens and OAuth2
- `references/file-upload-security.md` — safe uploads
- `references/cors-guide.md` — CORS configuration
- `references/logging-monitoring.md` — what to log and alert
- `references/ci-cd-security.md` — pipelines and secrets
- `references/api-design-security.md` — API hardening
- `references/owasp-top-10-for-ai-apps.md` — mapped threats
- `templates/env.example` — safe environment template
- `templates/security-config.yaml` — example config
- `templates/security-decision-record.md` — SDR template
- `templates/SECURITY.md` — project security policy template
- `templates/PROMPT.md` — copy-paste agent prompt
- `scripts/security-audit.sh` — local audit
- `.github/workflows/security-audit.yml` — CI audit workflow
