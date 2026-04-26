---
name: test-generation
description: Generate tests for existing code. Creates focused tests matching project testing patterns.
keywords:
  - test
  - testing
  - unit test
  - spec
  - add tests
---

# Test Generation

Use this skill when creating tests.

## When to Use

- Adding unit tests
- Creating integration tests
- Writing test specs

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
   - Add edge cases
   - Test error conditions
   - Keep tests focused and small

4. **Verify**
   - Run tests to ensure they pass
   - Fix any test issues

## Test Structure

- Arrange: Set up test data
- Act: Call the function
- Assert: Check the result

## Constraints

- Match existing test style and framework
- Keep tests isolated and independent
- Don't test more than one thing per test
- Use descriptive test names