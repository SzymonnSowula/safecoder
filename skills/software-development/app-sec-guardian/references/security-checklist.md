# Pre-Ship Security Checklist

Run this checklist before merging to `main` or deploying to production.

## Authentication

- [ ] Passwords are hashed with Argon2id, bcrypt, or scrypt (not MD5/SHA1/SHA256).
- [ ] Login endpoints return generic errors ("Invalid credentials") so attackers can't enumerate users.
- [ ] Session IDs are cryptographically random and rotated on privilege changes.
- [ ] Session cookies use `HttpOnly`, `Secure`, and `SameSite=Strict`/`Lax`.
- [ ] Sessions are invalidated on logout and password reset.
- [ ] Multi-factor authentication is offered for privileged accounts (if applicable).

## Signup & Email

- [ ] Rate limiting exists on signup, login, password reset, and resend-verification endpoints.
- [ ] Rate limits are enforced by IP (not just email).
- [ ] Email verification is required before the account can log in or perform privileged actions.
- [ ] Verification tokens are random, single-use, and expire within a reasonable window.
- [ ] Signup forms do not leak whether an email is already registered.

## Rate Limiting

- [ ] All public write endpoints have rate limits.
- [ ] Auth endpoints are limited per IP.
- [ ] Expensive endpoints (AI calls, exports, bulk operations) are limited per user.
- [ ] `429` responses include a `Retry-After` header.
- [ ] Rate-limit counters are stored in Redis or a shared database, not in-memory.

## Secrets

- [ ] No API keys, database URLs, or private tokens in frontend bundles.
- [ ] `.env` is in `.gitignore`.
- [ ] `.env.example` is committed with empty/placeholder values.
- [ ] Secrets are read from environment variables on the backend.
- [ ] A pre-commit hook or CI job scans for secrets.
- [ ] Service-role keys are never exposed to the browser.

## Input & Output

- [ ] All user input is validated on the server.
- [ ] Output is escaped before rendering in HTML, JS, CSS, URLs, and JSON.
- [ ] Rich HTML is sanitized server-side with an allow-list approach.
- [ ] File uploads are restricted by type, size, and content (not just extension).
- [ ] Uploaded files are served from a separate domain or with `Content-Disposition: attachment`.

## Headers & Browser Security

- [ ] `Content-Security-Policy` is set and blocks inline scripts by default.
- [ ] `X-Frame-Options` is `DENY` or `SAMEORIGIN`.
- [ ] `X-Content-Type-Options` is `nosniff`.
- [ ] `Referrer-Policy` is set to a safe value.
- [ ] `Permissions-Policy` restricts unused browser features.
- [ ] HTTPS is enforced with HSTS on production.

## Authorization

- [ ] Every resource read/modify checks that the current user owns it or has permission.
- [ ] Administrative endpoints require an explicit admin role.
- [ ] IDs from URL/body are not trusted without ownership verification.
- [ ] Database queries include ownership filters, not just post-fetch checks.

## CSRF

- [ ] Cookie-based sessions use SameSite cookies.
- [ ] State-changing forms include CSRF tokens.
- [ ] `Origin`/`Referer` headers are validated for sensitive actions.

## LLM / AI Features

- [ ] System instructions are separated from user input with delimiters.
- [ ] LLM output is validated against a schema before use.
- [ ] LLM output is escaped before rendering to users.
- [ ] LLM output never reaches `eval`, `exec`, SQL, shell, or filesystem operations unsupervised.
- [ ] AI API calls are rate-limited and cost-capped.

## Dependencies

- [ ] `npm audit` / `pip-audit` / equivalent shows no high/critical issues.
- [ ] Lockfiles are committed and up to date.
- [ ] Unused dependencies are removed.

## Logging & Monitoring

- [ ] Failed logins, password resets, and privilege changes are logged.
- [ ] Logs do not contain passwords, tokens, or PII in plain text.
- [ ] Suspicious activity (rapid requests, odd user agents) triggers alerts.
