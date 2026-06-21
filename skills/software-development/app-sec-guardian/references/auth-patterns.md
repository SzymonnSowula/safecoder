# Authentication & Authorization Patterns

## Email Verification Flow

1. User submits signup form.
2. Create user with `email_verified = false`.
3. Generate a cryptographically random token (32+ bytes).
4. Store a hash of the token with an expiry (e.g., 1 hour).
5. Send email with a link like `/verify?token=<raw_token>`.
6. On click, hash the raw token and look up the record.
7. If valid and not expired, set `email_verified = true`.
8. Delete the verification token.

```python
import secrets
import hashlib
from datetime import datetime, timedelta

def create_verification(user_id):
    raw = secrets.token_urlsafe(32)
    token_hash = hashlib.sha256(raw.encode()).hexdigest()
    expires = datetime.utcnow() + timedelta(hours=1)
    db.verification_tokens.insert({
        "user_id": user_id,
        "token_hash": token_hash,
        "expires_at": expires,
    })
    return raw
```

## Password Hashing

Use Argon2id, bcrypt, or scrypt.

```python
from argon2 import PasswordHasher

ph = PasswordHasher()
hash = ph.hash(password)
ph.verify(hash, password)
```

## Session Management

- Use random session IDs (not JWTs for browser sessions unless you have a revocation strategy).
- Store session data server-side; the cookie holds only the session ID.
- Set cookie flags:
  - `HttpOnly`
  - `Secure` (HTTPS only)
  - `SameSite=Strict` or `Lax`
- Rotate session ID on login and password change.
- Invalidate on logout.

## Resource Authorization

Every data access must include an ownership check.

```python
def get_order(user_id, order_id):
    return db.orders.find_one({
        "_id": order_id,
        "user_id": user_id,
    })
```

For admin access, check an explicit role:

```python
def admin_dashboard(user):
    if user.role != "admin":
        raise Forbidden()
```

## Row-Level Security (RLS)

If you use PostgreSQL/Supabase, enable RLS on every table and write policies that reference `auth.uid()`:

```sql
alter table orders enable row level security;

create policy "Users can see own orders"
  on orders
  for select
  using (user_id = auth.uid());
```
