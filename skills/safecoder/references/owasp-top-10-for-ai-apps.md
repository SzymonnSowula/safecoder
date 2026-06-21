# OWASP Top 10 Mapped to AI-Built Apps

This maps the OWASP Top 10 to the SafeCoder rules.

| OWASP Category | SafeCoder Rule | Check |
|----------------|----------------|-------|
| A01 Broken Access Control | Authorization on Every Resource Access | Verify ownership |
| A02 Cryptographic Failures | Passwords and Sessions, JWT/OAuth2 | Strong hashing, TLS, secure cookies |
| A03 Injection | SQL Injection Prevention, XSS Prevention, Prompt Injection Defense | Parameterize, escape, delimit |
| A04 Insecure Design | Rate Limiting, Email Verification | Design for abuse |
| A05 Security Misconfiguration | Secure Headers, CORS | Default deny |
| A06 Vulnerable Components | Dependencies and Supply Chain | Audit dependencies |
| A07 Identity/Auth Failures | Email Verification, Passwords and Sessions | Verify identity |
| A08 Data Integrity Failures | Webhook Security, Logging | Verify signatures |
| A09 Logging Failures | Logging and Monitoring | Log events safely |
| A10 SSRF | Secrets on Backend, Input Validation | No server-side requests to user URLs |

## AI-Specific Additions

- **LLM01 Prompt Injection** → separate instructions, validate output.
- **LLM02 Insecure Output Handling** → escape output, schema validation.
- **LLM03 Training Data Poisoning** → use trusted models, audit fine-tuning data.
- **LLM04 Model Denial of Service** → rate limits, cost caps.
- **LLM05 Supply Chain** → audit ML dependencies and model sources.
- **LLM06 Sensitive Data Disclosure** → don't send PII to AI APIs.
- **LLM07 Insecure Plugin Design** → validate plugin inputs and permissions.
- **LLM08 Excessive Agency** → limit what AI actions can perform.
- **LLM09 Overreliance** → human review for critical actions.
- **LLM10 Model Theft** → protect model endpoints with auth.
