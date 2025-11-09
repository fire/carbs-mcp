# ADR-002: Use Pythonx for Python Interop

**Status:** Accepted  
**Date:** 2025-01-09  
**Context:** Need to embed Python interpreter in Elixir application.

**Decision:** Use Pythonx library for Python interop

**Consequences:**
- **Pros:**
  - Embedded interpreter (same process, lower latency)
  - Native dependency management via pyproject.toml
  - Automatic data structure conversion
  - Actively maintained (latest release Aug 2025)
- **Cons:**
  - Still under development (though production-ready)
  - GIL limitations
  - Less mature than ErlPort

**Alternatives Considered:**
- ErlPort: More mature but process-based (higher latency)
- PyCall: Similar to ErlPort, process-based
- HTTP API: Too much overhead for in-process calls

