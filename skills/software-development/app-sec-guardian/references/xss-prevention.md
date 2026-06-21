# XSS Prevention Guide

XSS happens when user input is rendered as code. Prevent it by validating input, escaping output, and using CSP.

## Input Validation

Validate on the server before storing anything:

- Type and shape (JSON schema, Pydantic, Zod, Joi)
- Length limits
- Allowed characters (allow-list, not block-list)
- Expected format (email, URL, slug)

## Output Encoding

Escape based on where the value is rendered:

| Context | Function |
|---------|----------|
| HTML body | `& < > " '` |
| HTML attribute | `& < > "` |
| JavaScript | JSON-encode, never interpolate raw strings |
| CSS | Strict allow-list; never use user input in `url()` |
| URL | Percent-encode |

Most frameworks do this automatically if you use their templating:

- React: `{userInput}` is escaped by default. Dangerous: `dangerouslySetInnerHTML`.
- Vue: `{{ userInput }}` is escaped. Dangerous: `v-html`.
- Django/Jinja2: `{{ user_input }}` is escaped. Dangerous: `|safe`.

## CSP (Content Security Policy)

A good default:

```
Content-Security-Policy:
  default-src 'self';
  script-src 'self';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data: https:;
  font-src 'self';
  connect-src 'self';
  frame-ancestors 'none';
  base-uri 'self';
  form-action 'self';
```

If you must allow inline scripts, use nonces:

```
script-src 'self' 'nonce-abc123';
```

And render the nonce in the script tag:

```html
<script nonce="abc123">...</script>
```

## Sanitizing Rich HTML

When users need formatting, sanitize server-side:

- Python: `bleach` (deprecated but stable) or `nh3`
- Node: `DOMPurify` with `jsdom`
- Ruby: `sanitize`
- PHP: `HTML Purifier`

Allow-list only safe tags and attributes. Strip everything else.

Example Python:

```python
import nh3

clean = nh3.clean(
    user_html,
    tags={"b", "i", "em", "strong", "a", "p", "br"},
    attributes={"a": {"href"}},
    url_schemes={"https"},
)
```

## Testing for XSS

Try these payloads and confirm they render as text, not execute:

```html
<script>alert(1)</script>
<img src=x onerror=alert(1)>
" onmouseover="alert(1)
javascript:alert(1)
```
