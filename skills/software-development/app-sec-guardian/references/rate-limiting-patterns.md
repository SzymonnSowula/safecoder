# Rate Limiting Patterns

Use these recipes as starting points. Adjust limits to your traffic and threat model.

## Principles

1. Always limit by **IP address** for unauthenticated routes.
2. For authenticated routes, use **user ID + IP**.
3. Never rate-limit by email alone.
4. Use a shared store in production (Redis, database).
5. Return `429` with `Retry-After`.

## FastAPI + SlowAPI

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

@app.post("/api/contact")
@limiter.limit("3/hour")
def contact(request: Request):
    ...
```

## Express + express-rate-limit

```javascript
const rateLimit = require('express-rate-limit');

const authLimiter = rateLimit({
  windowMs: 5 * 60 * 1000, // 5 minutes
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.ip,
});

app.use('/auth/', authLimiter);
```

## Next.js API Routes + upstash/ratelimit

```typescript
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(5, '5 m'),
});

export async function POST(req: Request) {
  const ip = req.headers.get('x-forwarded-for') ?? '127.0.0.1';
  const { success, reset } = await ratelimit.limit(ip);
  if (!success) {
    return new Response('Too many requests', {
      status: 429,
      headers: { 'Retry-After': String(reset) },
    });
  }
  ...
}
```

## Nginx

```nginx
limit_req_zone $binary_remote_addr zone=auth:10m rate=5r/m;

server {
  location /auth/ {
    limit_req zone=auth burst=3 nodelay;
    ...
  }
}
```

## Recommended Limits

| Endpoint | Window | Max | Key |
|----------|--------|-----|-----|
| Signup | 5 min | 5 | IP |
| Login | 5 min | 5 | IP |
| Password reset | 5 min | 3 | IP |
| Contact form | 1 hour | 3 | IP |
| Email verification resend | 1 hour | 3 | user ID |
| Generic API reads | 1 min | 100 | IP |
| AI / expensive operations | 1 min | 10 | user ID |
| Admin actions | 1 min | 20 | user ID + IP |
