---
name: explain
description: Explain code. Default is a one-sentence summary plus a mental model. Add `verbose` to also get an ASCII diagram, key details, and a modification guide.
argument-hint: "[target] [verbose?]"
disable-model-invocation: true
---

Explain `$ARGUMENTS` clearly.

## Mode

If `$ARGUMENTS` includes the word `verbose` (for example, `/explain my-function verbose`), produce all five sections below. Strip the word `verbose` from the target name when interpreting what to explain.

Otherwise (the default), produce only sections 1 and 2 and stop. Day-to-day that's usually all you need.

## Sections

### 1. One-sentence summary
What does it do, and why does it exist? One sentence.

### 2. Mental model
An analogy or metaphor that captures the core idea. Relate it to something the developer already knows. One short paragraph.

### 3. Visual diagram (verbose only)

Draw an ASCII diagram showing the data and control flow. Keep it readable:

```
Input -> [Step A] -> [Step B] -> Output
              |
              v
        [Side Effect]
```

### 4. Key details (verbose only)

Walk through the important parts. Skip the obvious. Focus on:

- Non-obvious decisions (why this approach?)
- Edge cases and gotchas
- Dependencies and side effects

### 5. How to modify it (verbose only)

What would someone need to know to safely change this code? Where are the landmines?
