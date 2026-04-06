# Common Patterns

## Error Handling
```python
# Good
try:
    result = risky_operation()
except SpecificError as e:
    logger.error(f"Operation failed: {e}")
    raise CustomError("Message") from e

# Bad
try:
    result = risky_operation()
except:  # Catches everything including KeyboardInterrupt!
    pass
```

## Configuration
- Environment-specific configs
- Default values for development
- No secrets in config files
- Validation on load

## Logging
- Use structured logging
- Appropriate log levels
- Context in log messages
- No sensitive data in logs

## Documentation
- README for every module
- Docstrings for public APIs
- Examples in documentation
- Keep docs close to code

## Code Organization
- One class/file per concept
- Clear module boundaries
- Minimal dependencies
- High cohesion, low coupling
