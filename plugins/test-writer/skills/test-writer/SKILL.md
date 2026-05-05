---
name: test-writer
description: Write comprehensive tests for new or changed code. Use automatically when new features are added, functions are created, or behavior is modified.
# No disable-model-invocation. Claude can auto-trigger this when adding features.
# Add "disable-model-invocation: true" below if you prefer manual-only via /test-writer.
---

Write comprehensive tests for the code that was just added or changed.

## Step 1: Discover What Changed

- Check `git diff` and `git diff --cached` to identify new/modified functions, classes, and modules
- Read each changed file to understand the behavior being added
- Identify the project's existing test framework, patterns, and conventions by finding existing test files
- Place new test files next to the source files or in the project's established test directory. Match whatever the project already does

## Step 2: Analyze Every Code Path

For each new or modified function/method/component, map out:

- **Happy path**. Normal input, expected output
- **Edge cases**. Empty input, single element, boundary values (0, 1, -1, MAX_INT)
- **Null/undefined/nil**. What happens with missing data
- **Type boundaries**. Wrong types, type coercion traps
- **Error paths**. Invalid input, network failures, timeouts, permission denied
- **Concurrency**. Race conditions, parallel calls with shared state
- **State transitions**. Initial state, intermediate states, final state
- **Integration points**. How this code interacts with its dependencies

## Step 3: Write the Tests

For EACH scenario identified above, write a test. No skipping.

### Structure

- **One assertion per test**. If a test name needs "and", split it into two tests
- **Descriptive names**. Test names read as sentences describing the behavior:
  - `should return empty array when input is empty`
  - `should throw ValidationError when email format is invalid`
  - `should retry 3 times before failing on network timeout`
- **Arrange-Act-Assert**. Set up, execute, verify. Clear separation.

### What to Test

**Pure functions / business logic:**
- Every branch (if/else, switch, ternary)
- Every thrown error with exact error type and message
- Return value types and shapes
- Side effects (mutations, calls to external services)

**API endpoints / handlers:**
- Success response (status code, body shape, headers)
- Validation errors for each field (missing, wrong type, out of range)
- Authentication/authorization failures
- Rate limiting behavior if applicable
- Idempotency for non-GET methods

**UI components (if applicable):**
- Renders without crashing with required props
- Renders correct content for each state (loading, error, empty, populated)
- User interactions trigger correct callbacks (click, submit, type, select)
- Accessibility: focusable, keyboard navigable, correct ARIA attributes
- Conditional rendering. Each branch shows/hides correct elements

**Database / data layer:**
- CRUD operations return correct data
- Unique constraints reject duplicates
- Cascade deletes work as expected
- Transactions roll back on failure

**Async operations:**
- Successful resolution
- Rejection / error handling
- Timeout behavior
- Cancellation if supported
- Concurrent calls don't interfere

### Mocking Rules

- Prefer real implementations over mocks
- Only mock at system boundaries: network, filesystem, clock, random
- Never mock the code under test
- If you mock, verify the mock was called with expected arguments
- Reset mocks between tests. No shared state leaking

## Step 4: Verify

- Run the new tests. Confirm they all pass
- Temporarily break the code (change a return value or condition). Confirm at least one test fails
- If no test fails when code is broken, the tests are useless. Rewrite them
- Check coverage: every new function should have at least one test, every branch should be exercised

## Output

- Complete, runnable test file(s). Not snippets
- Tests grouped by the function/component they cover
- A brief summary: how many tests, what scenarios covered, any gaps you couldn't cover and why
