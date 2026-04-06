# Output Patterns for Tools

## Structured Output Formats

### JSON Output

Standard for API responses and data exchange:

```json
{
  "status": "success|error",
  "data": { ... },
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z",
    "version": "1.0"
  }
}
```

### Error Response

```json
{
  "status": "error",
  "error": {
    "code": "INVALID_INPUT",
    "message": "Description of what went wrong",
    "details": { ... }
  }
}
```

### Progress Updates

For long-running tasks:

```json
{
  "status": "in_progress",
  "progress": {
    "current": 45,
    "total": 100,
    "percentage": 45,
    "eta_seconds": 120
  }
}
```

## CLI Output Patterns

### Standard Output

```
[OK] Operation completed successfully
Result: 42 items processed
Output: ./output/results.json
```

### Verbose Output

```
[INFO] Starting operation...
[INFO] Loading configuration from config.yaml
[DEBUG] Parsed 3 settings
[INFO] Processing items...
[DEBUG] Processing item 1/42
[DEBUG] Processing item 2/42
...
[INFO] Operation completed in 1.23s
[OK] 42 items processed successfully
```

### Progress Bar

```
Processing: [████████░░░░░░░░░░░░] 45% (45/100) ETA: 2m 30s
```

## Report Generation

### Summary Report

```markdown
# Processing Summary

## Overview
- Items processed: 42
- Success rate: 95% (40/42)
- Duration: 1.23 seconds

## Results
| Item | Status | Details |
|------|--------|---------|
| Item 1 | ✅ Success | Processed in 0.01s |
| Item 2 | ❌ Failed | Invalid format |

## Errors
- Item 2: Invalid format (see logs)
- Item 5: Timeout after 30s
```

### CSV Output

```csv
id,name,status,processing_time
1,Item A,success,0.01
2,Item B,failed,0.05
3,Item C,success,0.02
```

## Logging Patterns

### Structured Logging

```json
{
  "timestamp": "2024-01-01T00:00:00Z",
  "level": "INFO",
  "message": "Processing started",
  "context": {
    "tool": "my-tool",
    "version": "1.0.0",
    "input_file": "data.csv"
  }
}
```

### Log Levels

- **DEBUG**: Detailed information for debugging
- **INFO**: General operational information
- **WARNING**: Potential issues that don't stop processing
- **ERROR**: Errors that affect specific operations
- **CRITICAL**: Errors that stop the entire process

## Template Patterns

### HTML Report Template

```html
<!DOCTYPE html>
<html>
<head>
    <title>{{tool_name}} Report</title>
    <style>
        body { font-family: sans-serif; margin: 40px; }
        .success { color: green; }
        .error { color: red; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>{{tool_name}} Report</h1>
    <p>Generated: {{timestamp}}</p>
    
    <h2>Summary</h2>
    <ul>
        <li>Total items: {{total}}</li>
        <li>Successful: <span class="success">{{success_count}}</span></li>
        <li>Failed: <span class="error">{{error_count}}</span></li>
    </ul>
    
    <h2>Details</h2>
    <table>
        <tr>
            <th>Item</th>
            <th>Status</th>
            <th>Details</th>
        </tr>
        {{#each items}}
        <tr>
            <td>{{name}}</td>
            <td class="{{status}}">{{status}}</td>
            <td>{{message}}</td>
        </tr>
        {{/each}}
    </table>
</body>
</html>
```

### Markdown Report Template

```markdown
# {{tool_name}} Report

Generated: {{timestamp}}

## Summary

| Metric | Value |
|--------|-------|
| Total Items | {{total}} |
| Successful | {{success_count}} ✅ |
| Failed | {{error_count}} ❌ |
| Duration | {{duration}}s |

## Details

{{#each items}}
### {{name}}
- **Status**: {{status}}
- **Message**: {{message}}
- **Duration**: {{processing_time}}s

{{/each}}

## Errors

{{#if errors}}
{{#each errors}}
- **{{item}}**: {{message}}
{{/each}}
{{else}}
No errors encountered.
{{/if}}
```

## Output Best Practices

1. **Be consistent** — Use the same format throughout
2. **Include metadata** — Timestamps, versions, tool info
3. **Handle errors gracefully** — Always return structured errors
4. **Support multiple formats** — JSON, CSV, Markdown as needed
5. **Make it parseable** — Structure output for automation
6. **Human-readable** — Include summaries and visual indicators
7. **Log everything** — Keep detailed logs for debugging
