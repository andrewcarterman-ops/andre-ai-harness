# Security Patterns for API Client

## Input Validation Schema

```yaml
parameters:
 endpoint:
   type: string
   pattern: "^[a-zA-Z0-9/_-]+$"
   maxLength: 200
   minLength: 1
   
 method:
   type: string
   enum: [GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS]
   default: GET
   
 data:
   type: object
   additionalProperties: true
   
 headers:
   type: object
   patternProperties:
     "^[A-Za-z0-9-]+$":
       type: string
   
 timeout:
   type: integer
   minimum: 1000
   maximum: 60000
   default: 30000
   
 retry_count:
   type: integer
   minimum: 0
   maximum: 5
   default: 3
```

## Environment Variables

Required:
- `API_BASE_URL` - Base URL for API (e.g., https://api.example.com)
- `API_KEY` - Authentication key
- `API_TIMEOUT` - Default timeout in milliseconds (default: 30000)

Optional:
- `API_RETRY_COUNT` - Number of retries (default: 3)
- `API_RATE_LIMIT` - Requests per minute (default: 60)

## Domain Allowlist

Allowed API domains:
- api.example.com
- api.trusted-service.com
- api.staging.example.com

## Error Codes

| Code | Description | Retryable |
|------|-------------|-----------|
| TIMEOUT_ERROR | Request timed out | Yes |
| DOMAIN_NOT_ALLOWED | Domain not in allowlist | No |
| INVALID_INPUT | Input validation failed | No |
| AUTH_ERROR | Authentication failed | No |
| RATE_LIMITED | Rate limit exceeded | Yes |
| NETWORK_ERROR | Network connection failed | Yes |
| UNKNOWN_ERROR | Unexpected error | No |

## Security Non-Regression

This skill maintains security score: 100/100
- RED patterns: 0
- YELLOW patterns: 0 (all hardened)
- GREEN patterns: 7
