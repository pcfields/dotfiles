# Gotchas

- A passing suite is not a safety net if it mocks the project's own modules (`vi.mock('./…')`, `jest.mock('../…')`): it pins calls, not behavior. In step 2, grep the covering tests for this, report it, and write characterization tests per the `tdd` skill's "Test doubles" order (MSW for HTTP), never in the existing file's mocking style.
