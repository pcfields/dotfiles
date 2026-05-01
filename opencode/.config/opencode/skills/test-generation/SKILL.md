---
name: test-generation
description: Generate tests for existing code. Creates focused tests matching project testing patterns.
keywords:
  - test
  - testing
  - unit test
  - spec
  - add tests
  - TDD
  - refactor
---

# Test Generation

Use this skill when creating tests. Tests are part of the design — they clarify requirements and ensure code works as intended.

## When to Use

- Adding unit tests for new or existing code
- Creating integration tests
- Writing test specs
- Establishing a safety net before refactoring

## Strategy by Context

### New Features: TDD

1. **Write the test first** — tests define the requirement
2. **Watch it fail** — confirms the test is valid
3. **Implement the minimum** to make the test pass
4. **Refactor** — improve code while keeping tests green

### Refactoring: Tests as Safety Net

1. **Write tests for current behavior first** — document what the code does now
2. **Refactor with confidence** — tests catch regressions
3. **Verify tests still pass** — ensures behavior unchanged

Without tests, refactoring is just guessing.

### Frontend/React: Behavior-Driven Testing

Write tests that describe **what users can do**, not how the component works internally.

**Avoid — implementation-focused:**
```javascript
test('button click handler is called', () => {
  const onClick = jest.fn();
  render(<PaymentButton onClick={onClick} />);
  fireEvent.click(screen.getByRole('button'));
  expect(onClick).toHaveBeenCalled();
});
```

**Prefer — behavior-focused:**
```javascript
test('user can make a payment', () => {
  render(<PaymentFlow />);
  userEvent.type(screen.getByLabelText(/card number/i), '4111111111111111');
  userEvent.type(screen.getByLabelText(/expiry/i), '12/25');
  userEvent.click(screen.getByRole('button', { name: /pay/i }));
  expect(screen.getByText(/payment successful/i)).toBeInTheDocument();
});
```

Behavior tests survive refactors and document what users can actually do.

## Workflow

1. **Analyze Code to Test**
   - Read the function/module to test
   - Identify inputs, outputs, and edge cases

2. **Match Project Patterns**
   - Look at existing tests in the project
   - Use the same testing framework
   - Follow naming conventions

3. **Write Tests**
   - Test happy path first
   - Add edge cases and error conditions
   - Keep tests focused and small

4. **Verify**
   - Run tests to ensure they pass
   - Fix any test issues

## Test Structure

- **Arrange**: Set up test data
- **Act**: Call the function
- **Assert**: Check the result

## Guidelines

- **Readable names**: Test names describe behavior, not the assertion
- **One concept per test**: Each test verifies one behavior
- **No implementation details**: Don't test private methods, internal state, or component structure
- **Real user interactions**: Use `userEvent` over `fireEvent` for frontend tests
- **Test the contract**: Input → output matters, not how it gets there

## When Unit Tests Aren't Enough

- **Integration/e2e**: For critical flows (payment, auth, checkout)
- **Snapshot tests**: Sparingly, only for complex UI that rarely changes
- **Visual regression**: For design-critical components

## Common Patterns by Language

| Context | Pattern | Example |
|---------|---------|---------|
| Node/JavaScript | Unit tests with test data | Jest, Vitest |
| React components | Behavior-driven | @testing-library/react |
| Python | Unit tests with fixtures | pytest |
| Rust | Doc tests + unit tests | #[test] or #[cfg(test)] |
| CLI commands | Integration tests with file I/O | cargo test or pytest |

## Constraints

- Match existing test style and framework
- Keep tests isolated and independent
- Don't test more than one thing per test
- Use descriptive test names
