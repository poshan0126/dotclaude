---
alwaysApply: true
---

# Testing

- Verify behavior, not implementation. Don't assert mock call counts when output values would do.
- Run the specific test file after changes, not the full suite. Faster feedback, fewer tokens.
- Flaky test? Fix it or delete it. Never retry to make it pass.
- Prefer real implementations. Mock only at system boundaries (network, filesystem, clock, randomness).
- One assertion per test. Test names describe behavior. Arrange-Act-Assert. No `if` or loops in tests.
- Never `expect(true)` or check a mock was called without verifying arguments.
