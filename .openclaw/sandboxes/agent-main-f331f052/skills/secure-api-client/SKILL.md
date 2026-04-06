---
name: secure-api-client
description: |
 A secure HTTP API client skill with built-in security controls.
 
 Use WHEN: Making API requests with proper authentication, rate limiting,
 timeout handling, and input validation.
 
 Trigger phrases: "make API call", "fetch data from API", "secure HTTP request",
 "call REST API", "API client request"

metadata:
 openclaw:
 requires:
 tools: [read, write, web_search]
 env: [API_BASE_URL, API_KEY, API_TIMEOUT]
 primaryEnv: API_KEY
---

# Secure API Client

## Overview

A production-ready API client implementing security best practices including:
- Input validation with JSON Schema
- Timeout handling on all network calls
- Environment-based secret management
- Rate limiting protection
- Error handling without information leakage

## Security Features

### 1. Input Validation (GREEN Pattern)

All inputs validated against strict schemas:

```yaml
parameters:
 endpoint:
   type: string
   pattern: "^[a-zA-Z0-9/_-]+$"
   maxLength: 200
   
 method:
   type: string
   enum: [GET, POST, PUT, DELETE, PATCH]
   default: GET
   
 timeout:
   type: integer
   minimum: 1000
   maximum: 60000
   default: 30000
```

### 2. Environment-Based Secrets (GREEN Pattern)

```yaml
metadata:
 openclaw:
 requires:
 env: [API_KEY, API_BASE_URL, API_TIMEOUT]
```

Never hardcode credentials. Always use environment variables.

### 3. Timeout Protection (YELLOW Pattern - Hardened)

All network calls have mandatory timeouts:
- Connection timeout: 5 seconds
- Read timeout: 30 seconds (configurable)
- Prevents DoS via hanging connections

### 4. Domain Allowlist (GREEN Pattern)

```yaml
allowed_domains:
 - api.example.com
 - api.trusted-service.com
```

Only allows requests to pre-approved domains.

## Usage Examples

### Basic GET Request

```yaml
Make a secure API request:
```yaml
secure_request:
 method: GET
 endpoint: /users/profile
 timeout: 30000
```
```

### POST with Data

```yaml
Send data securely:
```yaml
secure_request:
 method: POST
 endpoint: /users/update
 data:
   name: "John Doe"
   email: "john@example.com"
 timeout: 30000
```
```

### Handling Errors

All errors returned in structured format:
```json
{
 "success": false,
 "error": "Request timeout",
 "code": "TIMEOUT_ERROR",
 "retryable": true
}
```

## Security Checklist

- [x] Input validation with schemas (GREEN)
- [x] Environment variables for secrets (GREEN)
- [x] Timeout on all network calls (YELLOW hardened)
- [x] Domain allowlist validation (GREEN)
- [x] Error handling without info leakage (GREEN)
- [x] No hardcoded credentials
- [x] No command injection vectors
- [x] No path traversal risks
- [x] Rate limiting support

## Pattern Classification

| Pattern | Status | Implementation |
|---------|--------|----------------|
| Input Validation | GREEN | JSON Schema validation |
| Environment Secrets | GREEN | Required env vars |
| Network Timeout | YELLOW | 5s connect, 30s read |
| Domain Allowlist | GREEN | Pre-approved domains |
| Error Handling | GREEN | Structured errors |

## References

For advanced usage, see:
- `references/security-patterns.md` - Detailed security patterns
- `references/api-examples.md` - Extended examples
- `scripts/request_handler.py` - Request processing logic
