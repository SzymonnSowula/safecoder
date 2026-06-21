# Logging and Monitoring

## What to Log

- Failed logins
- Successful logins from new devices/locations
- Password reset requests
- Privilege changes (role, admin access)
- Access denials (403/404 on owned resources)
- Rate-limit hits
- AI API usage spikes
- File uploads
- Webhook deliveries

## What Never to Log

- Passwords
- API keys and tokens
- Credit card numbers
- Full raw PII (email, phone, SSN)
- Session identifiers
- Decrypted secrets

## Safe Log Example

```python
import hashlib

# Log a hashed user ID, not the raw ID or email
hashed_user = hashlib.sha256(str(user_id).encode()).hexdigest()[:16]
logger.info("login_success", user_hash=hashed_user, ip=ip)
```

## Alerts

Alert on:

- More than 10 failed logins per IP per minute
- Password reset spikes
- New admin assignments
- AI spend over threshold
- Unusual outbound traffic
- Unauthenticated access to admin endpoints

## Tools

- Log aggregation: Datadog, Splunk, ELK, Grafana Loki
- Error tracking: Sentry
- SIEM: Wazuh, Sentinel
