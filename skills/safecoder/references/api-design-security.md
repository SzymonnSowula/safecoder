# API Design Security

## General Principles

- Use HTTPS everywhere.
- Version your API (`/v1/`).
- Return minimal error details to clients.
- Use standard HTTP status codes.
- Validate all input against strict schemas.

## Authentication

- Prefer stateless bearer tokens or session cookies.
- Require authentication for all non-public endpoints.
- Use short-lived access tokens.

## Authorization

- Check permissions after authentication.
- Use policy-based access control for complex apps.
- Never rely on "security through obscurity" URL patterns.

## Input Validation

- Use JSON Schema, Zod, Pydantic, Joi, or OpenAPI spec.
- Reject unexpected fields (`additionalProperties: false`).
- Validate query params, headers, and path params too.

## Pagination

Always paginate list endpoints to prevent DoS:

```
GET /api/orders?limit=20&cursor=abc123
```

Max limit: 100.

## Idempotency

For state-changing operations, accept an `Idempotency-Key` header:

```
POST /api/payments
Idempotency-Key: <uuid>
```

## Error Responses

Bad:

```json
{"error": "SQL syntax error near 'users'"}
```

Good:

```json
{"error": "Invalid request"}
```

## API Keys

- Use prefixing to detect leaked keys (`sk_live_`, `sk_test_`).
- Allow users to rotate keys.
- Scope keys to specific permissions.
