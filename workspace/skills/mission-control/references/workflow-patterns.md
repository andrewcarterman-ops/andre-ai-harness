# Workflow Patterns for Tool Design

## Common Tool Patterns

### 1. Extract-Transform-Load (ETL)

For data processing tools:

```
Input → Extract → Transform → Load → Output
```

**Example**: CSV to Database importer
- Extract: Read CSV file
- Transform: Clean, validate, map fields
- Load: Insert into database

### 2. Adapter Pattern

For API integration tools:

```
Your Format → Adapter → External API Format
```

**Example**: Slack notifier
- Adapt your message to Slack's webhook format
- Handle authentication
- Transform responses

### 3. Pipeline Pattern

For multi-step processing:

```
Step 1 → Step 2 → Step 3 → ... → Output
```

**Example**: Document processor
- Step 1: Read file
- Step 2: Extract text
- Step 3: Analyze
- Step 4: Generate summary

### 4. Event-Driven Pattern

For automation tools:

```
Trigger → Handler → Action → Notification
```

**Example**: File watcher
- Trigger: File created in folder
- Handler: Process file
- Action: Move to processed folder
- Notification: Send completion email

## Tool Lifecycle

### 1. Initialization

```python
def init():
    # Load config
    # Set up logging
    # Validate environment
    # Connect to services
```

### 2. Processing

```python
def process(input_data):
    # Validate input
    # Transform data
    # Apply business logic
    # Generate output
```

### 3. Cleanup

```python
def cleanup():
    # Close connections
    # Save state
    # Log completion
```

## Error Handling Strategies

### Retry with Exponential Backoff

```python
import time

def retry_with_backoff(func, max_retries=3):
    for i in range(max_retries):
        try:
            return func()
        except Exception as e:
            if i == max_retries - 1:
                raise
            time.sleep(2 ** i)  # 1, 2, 4 seconds
```

### Circuit Breaker

```python
class CircuitBreaker:
    def __init__(self, threshold=5, timeout=60):
        self.failure_count = 0
        self.threshold = threshold
        self.timeout = timeout
        self.last_failure_time = None
    
    def call(self, func):
        if self.failure_count >= self.threshold:
            if time.time() - self.last_failure_time < self.timeout:
                raise Exception("Circuit breaker is open")
            self.failure_count = 0
        
        try:
            result = func()
            self.failure_count = 0
            return result
        except Exception as e:
            self.failure_count += 1
            self.last_failure_time = time.time()
            raise
```

### Graceful Degradation

```python
def process_with_fallback(input_data):
    try:
        # Try primary method
        return primary_method(input_data)
    except Exception:
        try:
            # Try secondary method
            return secondary_method(input_data)
        except Exception:
            # Return safe default
            return default_response()
```

## Configuration Patterns

### Environment-based Config

```python
import os

class Config:
    API_KEY = os.getenv('TOOL_API_KEY')
    BASE_URL = os.getenv('TOOL_BASE_URL', 'https://api.default.com')
    TIMEOUT = int(os.getenv('TOOL_TIMEOUT', '30'))
    DEBUG = os.getenv('TOOL_DEBUG', 'false').lower() == 'true'
```

### File-based Config

```yaml
# config.yaml
environment: production
api:
  key: ${API_KEY}  # Reference env var
  timeout: 30
features:
  caching: true
  retries: 3
logging:
  level: INFO
  format: json
```

## Testing Strategies

### Unit Tests

```python
def test_extract_data():
    input_data = "test"
    expected = {"field": "value"}
    result = extract_data(input_data)
    assert result == expected
```

### Integration Tests

```python
def test_full_pipeline():
    # Set up test environment
    setup_test_env()
    
    # Run tool
    result = run_tool(test_input)
    
    # Verify output
    assert result.exit_code == 0
    assert result.output_file.exists()
    
    # Clean up
    teardown_test_env()
```

### Mock External Services

```python
from unittest.mock import Mock, patch

def test_api_call():
    mock_response = Mock()
    mock_response.json.return_value = {"status": "ok"}
    
    with patch('requests.get', return_value=mock_response):
        result = call_api()
        assert result["status"] == "ok"
```
