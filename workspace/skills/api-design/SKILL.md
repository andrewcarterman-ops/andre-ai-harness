---
name: api-design
description: |
  REST API design patterns and best practices. Use when: (1) designing APIs,
  (2) reviewing API contracts, (3) implementing endpoints, (4) API versioning.
  
trigger_phrases:
  - "api"
  - "rest"
  - "endpoint"
  - "http"
  - "json api"
  - "openapi"
  
category: architecture
tags:
  - api
  - rest
  - backend
  
metadata:
  version: "1.0"
  author: "adapted-from-ecc"
  requires: ["secure-api-client"]
---

# API Design

## REST Principles

### Resource Naming
```
✅ Good:
GET    /users          # List users
GET    /users/123      # Get specific user
POST   /users          # Create user
PUT    /users/123      # Update user
DELETE /users/123      # Delete user

❌ Bad:
GET    /getUsers       # Verb in URL
POST   /createUser     # Not resource-based
GET    /users/123/get  # Unnecessary path
```

### HTTP Methods
| Method | Action | Idempotent |
|--------|--------|------------|
| GET    | Read   | Yes        |
| POST   | Create | No         |
| PUT    | Update | Yes        |
| PATCH  | Partial| Yes        |
| DELETE | Remove | Yes        |

## Response Format

### Success Response
```json
{
  "data": {
    "id": "123",
    "name": "John Doe",
    "email": "john@example.com"
  },
  "meta": {
    "timestamp": "2026-03-25T10:00:00Z"
  }
}
```

### Error Response
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid email format",
    "details": [
      {
        "field": "email",
        "issue": "must be valid email"
      }
    ]
  }
}
```

## Status Codes

- **200** OK - Success
- **201** Created - Resource created
- **204** No Content - Success, empty body
- **400** Bad Request - Client error
- **401** Unauthorized - Not authenticated
- **403** Forbidden - No permission
- **404** Not Found - Resource missing
- **409** Conflict - Resource exists
- **422** Unprocessable - Validation failed
- **429** Too Many Requests - Rate limited
- **500** Server Error - Unexpected error

## Versioning

### URL Versioning
```
/api/v1/users
/api/v2/users
```

### Header Versioning
```
Accept: application/vnd.api+json;version=2
```

## Pagination

```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 100,
    "total_pages": 5,
    "links": {
      "first": "/api/v1/users?page=1",
      "last": "/api/v1/users?page=5",
      "next": "/api/v1/users?page=2",
      "prev": null
    }
  }
}
```

## Rate Limiting

```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1648231200
```

## OpenAPI Spec

```yaml
openapi: 3.0.0
paths:
  /users:
    get:
      summary: List users
      parameters:
        - name: page
          in: query
          schema:
            type: integer
            default: 1
      responses:
        '200':
          description: Success
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserList'
```
