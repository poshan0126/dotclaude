---
paths:
  - "src/api/**"
  - "src/services/**"
  - "**/controllers/**"
  - "**/routes/**"
  - "**/handlers/**"
---

# Error Handling

- Use typed or custom error classes with error codes, not generic `Error("something went wrong")`.
- Never swallow errors silently. Log or rethrow with added context about what operation failed.
- Handle every rejected promise. No floating (unhandled) async calls.
- HTTP error responses: consistent shape (`{ error: { code, message } }`), correct status codes (400 validation, 401 auth, 404 not found, 500 unexpected).
- Never expose stack traces, internal paths, or raw database errors in production responses.
- Retry transient errors (network timeouts, rate limits) with exponential backoff. Fail fast on validation and auth errors. Don't retry them.
- Include correlation or request IDs in error logs when available.
