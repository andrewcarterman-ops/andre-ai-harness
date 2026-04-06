# Testing Rules

## Test Coverage
- Business logic: must be tested
- Edge cases: explicitly tested
- Happy path: always tested
- Error paths: tested

## Test Quality
- Tests are deterministic
- No dependencies between tests
- Fast execution
- Clear failure messages

## Test Organization
```
tests/
├── unit/           # Unit tests
├── integration/    # Integration tests
├── e2e/           # End-to-end tests
└── fixtures/      # Test data
```

## Test Naming
- `test_feature_behavior`
- `test_function_input_expected`
- Descriptive, not `test1`, `test2`

## Mocking Rules
- Mock external dependencies
- Don't mock what you own
- Verify mock calls
- Keep mocks simple

## Coverage Thresholds
- Minimum: 70%
- Target: 80%
- Critical paths: 100%
