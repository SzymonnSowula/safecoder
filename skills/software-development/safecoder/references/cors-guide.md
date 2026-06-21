# CORS Guide

## The Rule

Never use `Access-Control-Allow-Origin: *` on endpoints that return sensitive data or accept authenticated requests.

## Good Configuration

```python
from flask import Flask
from flask_cors import CORS

app = Flask(__name__)
CORS(app, origins=["https://app.example.com"], supports_credentials=True)
```

## Bad Configuration

```python
CORS(app, origins="*", supports_credentials=True)
```

This allows any website to make authenticated requests to your API.

## Dynamic Origins

If you must allow multiple origins, validate against an allow-list. Never reflect the request Origin blindly.

```python
ALLOWED_ORIGINS = {"https://app.example.com", "https://admin.example.com"}

origin = request.headers.get("Origin")
if origin in ALLOWED_ORIGINS:
    response.headers["Access-Control-Allow-Origin"] = origin
    response.headers["Access-Control-Allow-Credentials"] = "true"
```

## Preflight

For non-simple requests, browsers send an `OPTIONS` preflight. Ensure your server handles it and returns allowed methods/headers.

## Credentials

If you use cookies or Authorization headers, you must:

- Set `Access-Control-Allow-Credentials: true`
- Specify exact origins (not `*`)
