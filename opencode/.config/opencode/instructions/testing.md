# Testing Philosophy

## Principle: Tests are part of the design

Tests aren't an afterthought—they're a way to clarify requirements and ensure code works as intended. All meaningful changes should be covered by tests.

## Testing Strategies by Context

### For New Features: Test-Driven Development (TDD)

1. **Write the test first** - Tests define the requirement
2. **Watch it fail** - Confirms the test is valid
3. **Implement the minimum** to make the test pass
4. **Refactor** - Improve code while keeping tests green

This approach clarifies what "done" means before you write production code.

### For Refactoring: Tests as Safety Net

1. **Write tests for current behavior first** - Document what the code does now
2. **Refactor with confidence** - Tests catch regressions
3. **Verify tests still pass** - Ensures behavior unchanged

Without tests, refactoring is just guessing.

### For Frontend/React Components: Behavior-Driven Testing

Write tests that describe **what users can do**, not how the component works internally.

**❌ Implementation-focused (avoid):**
```javascript
test('button click handler is called', () => {
  const onClick = jest.fn();
  render(<PaymentButton onClick={onClick} />);
  fireEvent.click(screen.getByRole('button'));
  expect(onClick).toHaveBeenCalled();
});
```

**✅ Behavior-focused (preferred):**
```javascript
test('user can make a payment', () => {
  render(<PaymentFlow />);
  userEvent.type(screen.getByLabelText(/card number/i), '4111111111111111');
  userEvent.type(screen.getByLabelText(/expiry/i), '12/25');
  userEvent.click(screen.getByRole('button', { name: /pay/i }));
  expect(screen.getByText(/payment successful/i)).toBeInTheDocument();
});
```

**Benefits**:
- Tests survive refactors that don't change user-visible behavior
- Tests document what users can actually do
- Encourages thinking about user workflows early
- Easier to understand for non-frontend developers

### General Guidelines

- **Readable names**: Test names should describe the behavior, not the assertion
- **Arrange-Act-Assert**: Set up state, perform action, verify outcome
- **One concept per test**: A test should verify one behavior
- **No implementation details**: Don't test private methods, internal state, or component structure
- **Real user interactions**: Use `userEvent` instead of `fireEvent` for frontend tests
- **Test the contract, not the code**: What matters is input → output, not how it gets there

## When Tests Aren't Enough

- **Integration/e2e**: For critical flows like payment, authentication, checkout - use integration/e2e tests
- **Snapshot tests**: Sparingly, and only for complex UI that rarely changes
- **Visual regression**: For design-critical components

## Common Testing Patterns by Language

| Context | Pattern | Example |
|---------|---------|---------|
| Node/JavaScript functions | Unit tests with test data | Jest, Vitest |
| React components | Behavior-driven with user-library | @testing-library/react |
| Python functions | Unit tests with fixtures | pytest |
| Rust functions | Doc tests + unit tests | #[test] or #[cfg(test)] |
| CLI commands | Integration tests with file I/O | cargo test or pytest |
