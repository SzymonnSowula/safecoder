# Pre-Ship Security Checklist

Run this checklist before merging to `main` or deploying to production.

## Authentication

- [ ] Passwords are hashed with Argon2id, bcrypt, or scrypt (not MD5/SHA1/SHA256).
- [ ] Login endpoints return generic errors ("Invalid credentials").
- [ ] Session IDs are cryptographically random and rotated on privilege changes.
- [ ] Session cookies use `HttpOnly`, `Secure`, and `SameSite=Strict`/`Lax`.
- [ ] Sessions are invalidated on logout and password reset.
- [ ] Email verification is required before privileged actions.
- [ ] Multi-factor authentication is offered for privileged accounts (if applicable).

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
- [ ] Rich HTML is sanitized server-side with an allow-list.
- [ ] SQL queries use parameterized statements or ORM methods.
- [ ] No user input reaches shell, eval, exec, or raw SQL.
- [ ] File uploads are restricted by MIME type, extension, size, and content.
- [ ] Uploaded files are served from a separate domain or with `Content-Disposition: attachment`.
- [ ] File paths are resolved and verified to stay inside the allowed base directory.

## Headers & Browser Security

- [ ] `Content-Security-Policy` is set and blocks inline scripts by default.
- [ ] `X-Frame-Options` is `DENY` or `SAMEORIGIN`.
- [ ] `X-Content-Type-Options` is `nosniff`.
- [ ] `Referrer-Policy` is set to a safe value.
- [ ] `Permissions-Policy` restricts unused browser features.
- [ ] HTTPS is enforced with HSTS on production.

## CORS

- [ ] Authenticated endpoints do not use `Access-Control-Allow-Origin: *`.
- [ ] Allowed origins are configured explicitly.
- [ ] `Access-Control-Allow-Credentials` is only set with exact origins.

## Authorization

- [ ] Every resource read/modify checks that the current user owns it or has permission.
- [ ] Administrative endpoints require an explicit admin role.
- [ ] IDs from URL/body are not trusted without ownership verification.
- [ ] Database queries include ownership filters.

## CSRF

- [ ] Cookie-based sessions use SameSite cookies.
- [ ] State-changing forms include CSRF tokens.
- [ ] `Origin`/`Referer` headers are validated for sensitive actions.

## JWT / OAuth2

- [ ] Strong signing algorithms (`RS256`, `ES256`) are used.
- [ ] `alg: none` is rejected.
- [ ] Access tokens have short expiry.
- [ ] Refresh tokens are single-use and rotated.
- [ ] Tokens are stored in `HttpOnly` cookies or secure storage, not localStorage.

## WebSockets

- [ ] WebSocket handshake authenticates the user.
- [ ] Messages are rate-limited per connection.
- [ ] Every incoming message is validated against a schema.
- [ ] Sensitive data is not broadcast to all clients.

## Webhooks

- [ ] Webhook signatures are verified with a shared secret.
- [ ] Idempotency keys prevent duplicate processing.
- [ ] Webhook receivers are rate-limited.
- [ ] Event types are validated against an allow-list.

## LLM / AI Features

- [ ] System instructions are separated from user input with delimiters.
- [ ] LLM output is validated against a schema before use.
- [ ] LLM output is escaped before rendering to users.
- [ ] LLM output never reaches `eval`, `exec`, SQL, shell, or filesystem operations unsupervised.
- [ ] AI API calls are rate-limited and cost-capped.
- [ ] User PII is not sent to AI APIs unless necessary and approved.

## Markdown Rendering

- [ ] Raw HTML is disabled or aggressively sanitized.
- [ ] Links use `rel="nofollow noopener"`.
- [ ] Output is escaped before rendering.

## Dependencies

- [ ] `npm audit` / `pip-audit` / `cargo audit` shows no high/critical issues.
- [ ] Lockfiles are committed and up to date.
- [ ] Unused dependencies are removed.

## CI/CD

- [ ] Secrets are stored in platform secret manager, not workflow files.
- [ ] Branch protection requires PR + review for main.
- [ ] Security scans run on every PR.
- [ ] Production deployments require approval.

## Logging & Monitoring

- [ ] Failed logins, password resets, and privilege changes are logged.
- [ ] Logs do not contain passwords, tokens, or PII in plain text.
- [ ] Suspicious activity triggers alerts.

## Documentation

- [ ] SECURITY.md exists and contains a reporting contact.
- [ ] Any relaxed rule is documented in a Security Decision Record.
