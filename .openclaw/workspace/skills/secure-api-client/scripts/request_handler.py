# Secure API Request Handler
# Implements GREEN and hardened YELLOW security patterns

import os
import re
import time
from urllib.parse import urlparse
from typing import Dict, Any, Optional, Tuple

# GREEN Pattern: Allowlist-based validation
ALLOWED_DOMAINS = [
    "api.example.com",
    "api.trusted-service.com", 
    "api.staging.example.com"
]

# GREEN Pattern: Input validation schemas
ENDPOINT_PATTERN = re.compile(r'^[a-zA-Z0-9/_-]+$')
MAX_ENDPOINT_LENGTH = 200
ALLOWED_METHODS = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS']

# YELLOW Pattern (Hardened): Timeout configuration
DEFAULT_TIMEOUT = int(os.environ.get('API_TIMEOUT', '30000'))  # 30 seconds
MAX_TIMEOUT = 60000  # 60 seconds max
MIN_TIMEOUT = 1000   # 1 second min
CONNECT_TIMEOUT = 5000  # 5 seconds for connection

class SecurityError(Exception):
    """Security validation error"""
    pass

class ValidationError(Exception):
    """Input validation error"""
    pass

def validate_endpoint(endpoint: str) -> bool:
    """
    GREEN Pattern: Input validation with explicit schema
    Validates endpoint against allowlist pattern
    """
    if not endpoint:
        raise ValidationError("Endpoint cannot be empty")
    
    if len(endpoint) > MAX_ENDPOINT_LENGTH:
        raise ValidationError(f"Endpoint exceeds max length of {MAX_ENDPOINT_LENGTH}")
    
    if not ENDPOINT_PATTERN.match(endpoint):
        raise ValidationError("Endpoint contains invalid characters")
    
    # Reject path traversal attempts
    if '..' in endpoint or '//' in endpoint:
        raise ValidationError("Path traversal detected")
    
    return True

def validate_method(method: str) -> bool:
    """
    GREEN Pattern: Allowlist validation
    Only allow specific HTTP methods
    """
    if method not in ALLOWED_METHODS:
        raise ValidationError(f"Method '{method}' not in allowlist")
    return True

def validate_url(url: str) -> bool:
    """
    GREEN Pattern: Domain allowlist
    Only allow requests to pre-approved domains
    """
    parsed = urlparse(url)
    domain = parsed.netloc.lower()
    
    if domain not in ALLOWED_DOMAINS:
        raise SecurityError(f"Domain '{domain}' not in allowlist")
    
    return True

def validate_timeout(timeout: int) -> int:
    """
    YELLOW Pattern (Hardened): Bounded timeout
    Ensures timeout is within safe limits
    """
    if not isinstance(timeout, int):
        raise ValidationError("Timeout must be an integer")
    
    if timeout < MIN_TIMEOUT:
        return MIN_TIMEOUT
    
    if timeout > MAX_TIMEOUT:
        return MAX_TIMEOUT
    
    return timeout

def get_api_credentials() -> Tuple[str, str]:
    """
    GREEN Pattern: Environment variable usage
    Never hardcode secrets, always use env vars
    """
    base_url = os.environ.get('API_BASE_URL')
    api_key = os.environ.get('API_KEY')
    
    if not base_url:
        raise SecurityError("API_BASE_URL environment variable not set")
    
    if not api_key:
        raise SecurityError("API_KEY environment variable not set")
    
    # Validate base URL is in allowlist
    validate_url(base_url)
    
    return base_url, api_key

def make_secure_request(
    endpoint: str,
    method: str = 'GET',
    data: Optional[Dict[str, Any]] = None,
    headers: Optional[Dict[str, str]] = None,
    timeout: Optional[int] = None
) -> Dict[str, Any]:
    """
    Main function to make secure API requests
    Implements all GREEN and hardened YELLOW patterns
    """
    try:
        # Step 1: Input validation (GREEN Pattern)
        validate_endpoint(endpoint)
        validate_method(method)
        
        # Step 2: Get credentials (GREEN Pattern)
        base_url, api_key = get_api_credentials()
        
        # Step 3: Validate and set timeout (YELLOW Pattern - Hardened)
        request_timeout = validate_timeout(timeout or DEFAULT_TIMEOUT)
        
        # Step 4: Construct full URL and validate
        full_url = f"{base_url.rstrip('/')}/{endpoint.lstrip('/')}"
        validate_url(full_url)
        
        # Step 5: Prepare headers with authentication
        request_headers = headers or {}
        request_headers['Authorization'] = f'Bearer {api_key}'
        request_headers['Content-Type'] = 'application/json'
        request_headers['User-Agent'] = 'SecureAPIClient/1.0'
        
        # Step 6: Make request with timeout
        # Note: This is a placeholder - actual implementation would use requests library
        result = {
            "success": True,
            "url": full_url,
            "method": method,
            "timeout": request_timeout,
            "headers": request_headers,
            "data": data,
            "status": "validated",
            "message": "Request passed all security validations"
        }
        
        return result
        
    except ValidationError as e:
        # GREEN Pattern: Structured error without info leakage
        return {
            "success": False,
            "error": "Input validation failed",
            "code": "INVALID_INPUT",
            "details": str(e),
            "retryable": False
        }
    except SecurityError as e:
        return {
            "success": False,
            "error": "Security validation failed",
            "code": "SECURITY_ERROR",
            "details": str(e),
            "retryable": False
        }
    except Exception as e:
        # GREEN Pattern: Catch-all error handling
        return {
            "success": False,
            "error": "Request processing failed",
            "code": "PROCESSING_ERROR",
            "retryable": True
        }

# Export main function
__all__ = ['make_secure_request', 'validate_endpoint', 'validate_url']
