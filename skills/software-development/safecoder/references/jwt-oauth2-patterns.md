# JWT and OAuth2 Patterns

## JWT Best Practices

### Signing

- Use asymmetric algorithms: `RS256` or `ES256`.
- Never use `alg: none`.
- Avoid `HS256` unless the secret is long and stored in a hardware security module or secret manager.
- Rotate signing keys periodically.

### Claims

Always validate:

- `iss` (issuer)
- `aud` (audience)
- `exp` (expiration)
- `nbf` (not before)
- `sub` (subject / user ID)

### Storage

- Browser: store in `HttpOnly`, `Secure`, `SameSite=Strict` cookie.
- Avoid localStorage for sensitive tokens.
- Mobile: use Keychain / Keystore.

### Expiration

- Access tokens: 5-15 minutes.
- Refresh tokens: 7-30 days, single-use, rotated on every refresh.
- Invalidate refresh tokens on logout and password change.

## FastAPI + python-jose Example

```python
from jose import jwt, JWTError
from fastapi import HTTPException, Depends
from fastapi.security import HTTPBearer

SECRET_KEY = os.environ["JWT_SECRET_KEY"]
ALGORITHM = "HS256"  # Prefer RS256 in production
bearer = HTTPBearer()

def decode_token(token: str = Depends(bearer)):
    try:
        payload = jwt.decode(token.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        if payload.get("iss") != EXPECTED_ISSUER:
            raise HTTPException(status_code=401, detail="Invalid issuer")
        return payload
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")
```

## OAuth2 with PKCE (Next.js / SPA)

Use PKCE for any client that cannot keep a secret (SPAs, mobile).

```
1. Client generates code_verifier and code_challenge.
2. Redirects user to /authorize?code_challenge=...&response_type=code
3. Provider returns authorization code.
4. Client exchanges code + code_verifier for tokens.
```

Never put the client secret in frontend code. Server-side confidential clients only.

## Token Revocation

- Maintain a blocklist of revoked tokens in Redis/database.
- Check every request against the blocklist.
- Or use short-lived tokens + refresh rotation so revocation is rarely needed.
