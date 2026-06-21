# CI/CD Security

## Secrets

- Store secrets in GitHub/GitLab secret managers or Vault.
- Never put secrets in workflow YAML files.
- Use environment-specific secrets (dev, staging, prod).
- Rotate deployment keys regularly.

## Least Privilege

- CI runners should have minimal permissions.
- Use short-lived tokens where possible.
- Separate build and deploy jobs with different credentials.

## Workflow Security

```yaml
name: Security Audit
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Secret scan
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          base: main
      - name: Dependency audit
        run: npm audit --audit-level=high
      - name: Run SafeCoder audit
        run: bash scripts/security-audit.sh
```

## Deployment

- Require approval for production deployments.
- Sign container images and artifacts.
- Scan Docker images for vulnerabilities.
- Disable direct pushes to main; require PR + review.
