# Performance Rules

## Premature Optimization
- DON'T optimize prematurely
- DO measure before optimizing
- DO optimize hot paths

## Code Efficiency
- Use appropriate data structures
- Avoid N+1 queries
- Cache expensive operations
- Lazy loading where appropriate

## Resource Management
- Close files/connections properly
- Use `with` statements (Python)
- Clean up resources
- Monitor memory usage

## Performance Checklist
- [ ] No obvious bottlenecks
- [ ] Queries are efficient
- [ ] Caching strategy defined
- [ ] Resource usage monitored

## Measurement
- Profile before optimizing
- Measure real-world usage
- Benchmark critical paths
- Monitor in production
