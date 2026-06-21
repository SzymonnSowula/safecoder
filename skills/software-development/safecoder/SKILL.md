---
name: safecoder
description: "Use when an AI coding agent is building or reviewing a web app, API, or desktop app and you want security guardrails applied by default: rate limiting, email verification, secret handling, XSS/CSRF/CSP hardening, prompt injection defense, and authorization."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [security, ai-agents, web-apps, apis, authentication, rate-limiting, xss, prompt-injection]
    related_skills: [requesting-code-review, systematic-debugging, nextjs-development]
---

# SafeCoder

Apply security-by-default to every feature an AI coding agent builds. This skill covers rate limiting, email verification, secret storage, XSS/CSRF/CSP hardening, prompt injection defense, authorization, and safe dependency practices.

AI agents ship working apps, not safe ones. Use this skill to force a security review before any feature is considered done.

## When to Use

- Building or reviewing auth flows (signup, login, password reset, email verification).
- Adding public-facing forms or API endpoints (signup, contact, search, webhook receivers).
- Integrating third-party services (Firebase, Supabase, OpenAI, Stripe, etc.).
- Rendering user-generated content or passing user input to an LLM.
- Shipping a frontend that talks to a backend or database.
- Performing a final pre-merge or pre-ship security audit.

Don't use this skill as a substitute for a full penetration test or formal security audit. It catches common AI-generated vulnerabilities, not zero-days.

## Core Security Rules

Apply these rules to every feature unless the user explicitly opts out.

### 1. Rate Limiting

Every public endpoint that can trigger email, database writes, authentication, or external API calls must have rate limiting.

- Limit by **IP address** first. Email-only limits are useless because attackers rotate emails.
- For authenticated routes, combine IP + user ID.
- Match limits to the action:
  - Signup, login, password reset: 5 attempts per 5 minutes per IP.
  - Contact forms: 3 submissions per hour per IP.
  - Generic API reads: 100 requests per minute per IP.
  - Expensive operations (AI calls, exports): 10 per minute per user.
- Return `429 Too Many Requests` with a `Retry-After` header.
- Use a real store (Redis, database) in production; in-memory stores reset on restart and fail horizontally.

Example (FastAPI + SlowAPI):

```python
from slowapi import Limiter
from slowapi.util import get_remote_address
from fastapi import FastAPI, Request

limiter = Limiter(key_func=get_remote_address)
app = FastAPI()
app.state.limiter = limiter

@app.post("/auth/signup")
@limiter.limit("5/minute")
def signup(request: Request):
    ...
```

### 2. Email Verification

Signup is not complete until the email is verified.

- Send a one-time link or code to the registered email before the account can log in or perform privileged actions.
- Tokens must be random, single-use, and expire (e.g., 1 hour).
- Do not expose whether an email is already registered on the signup form (use a generic message).
- Mark unverified accounts clearly; restrict actions until verified.

### 3. Secrets Stay on the Backend

No API keys, service-role keys, database URLs, or private tokens in frontend code.

- Frontend gets only **public/anon keys** with Row-Level Security (RLS) or minimal permissions.
- All privileged operations go through your backend API.
- Read secrets from environment variables, never hard-code them.
- Commit `.env.example` with empty/placeholder values; put `.env` in `.gitignore`.
- Scan commits for secrets with `gitleaks`, `trufflehog`, or a pre-commit hook.

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
OPENAI_API_KEY = os.environ["OPENAI_API_KEY"]
```

### 4. XSS Prevention

Treat every byte of user input as untrusted.

- Validate input on the server (type, length, allowed characters, allow-lists).
- Escape output everywhere it is rendered (HTML, JavaScript, CSS, URLs, JSON).
- If rich HTML is required, use a strict sanitizer like DOMPurify on the client and a server-side sanitizer on save.
- Use a Content Security Policy (CSP) that:
  - Blocks inline scripts (`script-src 'self'`)
  - Restricts script sources
  - Sets `default-src 'self'`
  - Uses nonces or hashes if inline scripts are unavoidable
- Set `X-Content-Type-Options: nosniff` so browsers don't guess MIME types.

### 5. CSRF Protection

State-changing endpoints must verify the request origin.

- Use SameSite cookies (`Lax` or `Strict`).
- For cookie-based sessions, require a CSRF token for POST/PUT/DELETE.
- Prefer Authorization headers with bearer tokens for SPAs/APIs; they are not vulnerable to CSRF.
- Validate `Origin` / `Referer` headers for sensitive actions.

### 6. Secure Headers

Add these headers to every response:

```
Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=(), camera=()
Strict-Transport-Security: max-age=63072000; includeSubDomains; preload   (HTTPS only)
```

### 7. Prompt Injection Defense

When user input is sent to an LLM:

- Separate system instructions from user content with delimiters (XML tags, markdown blocks).
- Treat the LLM output as untrusted; validate it against a schema before acting on it.
- Do not expose raw LLM output directly to users without escaping.
- Never let the LLM construct SQL, shell commands, or file paths from user input unsupervised.
- Use a trusted parser for structured output, not regex on free text.

Example delimiter pattern:

```
System: You are a helpful assistant. Return JSON with keys "action" and "params".

User message:
<user_input>
{{user_input}}
</user_input>
```

### 8. Authorization on Every Resource Access

Authentication is not enough.

- For every request that reads or modifies a resource, verify the logged-in user owns it or has explicit permission.
- Never trust IDs from the URL or body without checking ownership.
- Use row-level security in databases where available.

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

- Hash passwords with Argon2, bcrypt, or scrypt. Never MD5 or SHA1.
- Use slow, salted hashing.
- Sessions:
  - Use cryptographically random session IDs.
  - Set `HttpOnly`, `Secure`, `SameSite=Strict` on cookies.
  - Rotate session IDs on privilege changes (login, password change).
  - Invalidate sessions on logout and password reset.

### 10. Dependencies and Supply Chain

- Keep dependencies updated; run `npm audit`, `pip-audit`, or equivalent regularly.
- Pin versions in lockfiles.
- Avoid installing packages you don't need.
- Review packages with few maintainers or sudden spikes in popularity.

## Common Pitfalls

1. **Rate limiting by email only.** An attacker can generate infinite email addresses. Always start with IP, then layer user ID for authenticated routes.

2. **Trusting frontend validation.** Anything the browser enforces can be bypassed. Validate every input again on the server.

3. **Putting service-role keys in the client.** Supabase and Firebase make this easy to do by accident. Use RLS and keep service keys server-side.

4. **Rendering user input as HTML without escaping.** This is the root cause of most stored XSS. Escape by default; sanitize only when rich content is required.

5. **Letting the LLM execute user commands.** Never pass LLM output directly into `eval`, `exec`, `os.system`, SQL, or file operations. Validate and parameterize.

6. **Forgetting security headers.** Missing `X-Frame-Options` enables clickjacking; missing CSP enables XSS payloads.

7. **Skipping ownership checks.** A logged-in user can still access another user's data if you don't verify `resource.user_id == current_user.id`.

8. **Committing `.env` files.** One `.env` commit can leak database URLs, API keys, and signing secrets forever (git history remembers).

## One-Shot Recipes

### Add Rate Limiting to a New Auth Endpoint

1. Identify the route.
2. Add `@limiter.limit("5/minute")` (or framework equivalent).
3. Ensure the key function is IP-based (`get_remote_address`).
4. Return `429` with `Retry-After` when exceeded.
5. Test by hitting the endpoint 6 times from the same IP.

### Integrate a Third-Party API Safely

1. Create a backend route that calls the API.
2. Move the API key to an environment variable.
3. Add rate limiting to the backend route.
4. Validate and sanitize user input before sending it to the API.
5. Validate the API response before returning it to the frontend.
6. Remove any key from frontend code and rotate the key if it was exposed.

### Add Email Verification to Signup

1. On signup, create the user with `email_verified = false`.
2. Generate a random token and store a hash of it with an expiry.
3. Send an email with a verification link containing the raw token.
4. On link click, verify the token hash and set `email_verified = true`.
5. Block privileged actions until verified.

### Harden a Form Against XSS

1. Validate input server-side (length, type, allow-list characters).
2. Escape the value when rendering in HTML, JS, CSS, or URLs.
3. If rich HTML is needed, sanitize with a server-side library.
4. Add CSP headers that disallow inline scripts.
5. Test with `<script>alert(1)</script>` and verify it is not executed.

## Verification Checklist

Before any feature or PR is considered complete:

- [ ] Rate limits exist on all public write endpoints and authentication routes.
- [ ] Rate limits are IP-based (with user ID fallback for authenticated routes), not email-only.
- [ ] Email verification is required before privileged actions.
- [ ] No secrets are in frontend bundles or committed source files.
- [ ] User input is validated on the server and escaped on output.
- [ ] CSP and security headers are configured.
- [ ] CSRF protection is in place for cookie-based sessions.
- [ ] LLM inputs/outputs use delimiters and output validation.
- [ ] Every resource access checks ownership or permission.
- [ ] Passwords are hashed with Argon2/bcrypt/scrypt.
- [ ] Session cookies use `HttpOnly`, `Secure`, and `SameSite`.
- [ ] `.env` is in `.gitignore` and `env.example` is committed.
- [ ] Dependencies are scanned for known vulnerabilities.

## Links

- `references/security-checklist.md` — full pre-ship checklist
- `references/rate-limiting-patterns.md` — framework-specific rate limit recipes
- `references/xss-prevention.md` — output encoding and CSP guide
- `references/prompt-injection-defense.md` — LLM hardening patterns
- `references/auth-patterns.md` — email verify, sessions, authz
- `templates/env.example` — safe environment variable template
- `templates/security-config.yaml` — example rate-limit / CSP config
- `scripts/security-audit.sh` — quick local security scan
