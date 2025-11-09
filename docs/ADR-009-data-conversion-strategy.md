# ADR-009: Data Conversion Strategy

**Status:** Accepted **Date:** 2025-01-09 **Context:** Need to convert between
Elixir and Python data structures.

**Decision:** Use JSON as intermediate format with custom conversion for special
cases (:inf atoms, structs)

**Consequences:**

- **Pros:**
  - JSON is well-supported in both languages
  - Easy to debug (human-readable)
  - Handles nested structures well
  - Pythonx provides decode/encode helpers
- **Cons:**
  - Some overhead (JSON encoding/decoding)
  - Need special handling for :inf, :"-inf" atoms
  - Type information may be lost

**Alternatives Considered:**

- Direct Python object passing: Not supported by Pythonx
- Binary format: Too complex, harder to debug
- Custom serialization: More work, JSON is sufficient
