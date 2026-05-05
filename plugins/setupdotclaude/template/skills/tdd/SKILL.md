---
name: tdd
description: Test-Driven Development loop. Write a failing test first, then the minimum code to pass it, then refactor. Repeat.
argument-hint: "[feature description or function signature]"
disable-model-invocation: true
---

Build the following using strict Test-Driven Development:

**Feature**: $ARGUMENTS

## The TDD Cycle

Repeat this cycle for each behavior. Never skip steps.

### Red: Write a Failing Test

1. Write ONE test for the smallest next behavior (not the whole feature)
2. The test must:
   - Describe the behavior in its name: `should return 0 for empty cart`
   - Use Arrange-Act-Assert structure
   - Assert specific values, not vague truths
3. **Run the test. It MUST fail.** If it passes, either:
   - The behavior already exists (skip to the next behavior)
   - The test is wrong (it's not testing what you think. Fix it)
4. Verify the failure message makes sense. It should tell you what's missing

### Green: Write the Minimum Code to Pass

1. Write the **simplest, most obvious code** that makes the failing test pass
2. Don't generalize. Don't make it elegant. Don't handle cases the test doesn't cover.
3. Hardcoding is fine if only one test exists for that path. The next test will force generalization
4. **Run the test. It MUST pass.** If it doesn't, fix the code (not the test. The test defined the behavior)
5. Run ALL tests. Nothing previously passing should break.

### Refactor: Clean Up Without Changing Behavior

1. Look for: duplication, unclear names, functions doing too much, magic values
2. Make ONE improvement at a time
3. **Run ALL tests after each change.** If anything breaks, undo immediately.
4. Stop refactoring when the code is clean enough. Don't gold-plate

## Choosing What to Test Next

Work from simple to complex:
1. **Degenerate cases**. Null input, empty collection, zero
2. **Happy path**. The simplest valid input
3. **Variations**. Different valid inputs that exercise different branches
4. **Edge cases**. Boundary values, max sizes, special characters
5. **Error cases**. Invalid input, failures, exceptions
6. **Integration**. How this connects to the rest of the system

Each test should require a small code change. If you need to write more than ~10 lines of production code to pass a test, the test is too big. Split it.

## Rules

- **Never write production code without a failing test that demands it.**
- **Never write more than one failing test at a time.** One red → green → refactor cycle at a time.
- **The test drives the design.** If the code is hard to test, the design is wrong. Change the design, not the test approach.
- **Don't mock what you own.** If you need to mock your own code to test it, the code needs restructuring.
- **Commit after each green+refactor cycle.** Small, passing, meaningful commits.

## Output

After each cycle, briefly state:
- **Test**: what behavior was added
- **Code**: what changed to make it pass
- **Refactor**: what was cleaned up (or "none needed")

When the feature is complete, provide a summary of all behaviors covered and any gaps that would need integration or manual testing.
