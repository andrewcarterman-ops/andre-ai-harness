# Security Rules

## Secrets Management
- NEVER commit secrets to git
- Use environment variables
- Rotate keys regularly
- Use `.env` files (gitignored)

## Input Validation
- Validate all inputs
- Sanitize user data
- Use parameterized queries
- Escape output

## Dependencies
- Keep dependencies updated
- Audit for vulnerabilities
- Pin versions in production
- Review before adding

## Code Security
- No SQL injection (parameterized queries)
- No XSS (output encoding)
- No command injection
- Proper auth checks

## Review Checklist
- [ ] No hardcoded secrets
- [ ] Input validated
- [ ] Auth enforced
- [ ] Error messages safe
