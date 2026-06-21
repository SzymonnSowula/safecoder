# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| x.y.z   | :white_check_mark: |
| < x.y.z | :x:                |

## Reporting a Vulnerability

Please report security issues to [security@example.com]. Do not open public issues for vulnerabilities.

We aim to respond within 48 hours.

## Security Practices

This project follows the SafeCoder security guidelines:

- Rate limiting on all public endpoints.
- Email verification for accounts.
- Secrets stored in environment variables, never in frontend code.
- Parameterized queries and input validation.
- CSP and security headers.
- Dependency scanning in CI.

## Audit

Run the local security audit:

```bash
bash scripts/security-audit.sh
```
