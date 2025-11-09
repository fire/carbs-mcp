# ADR-010: Mix Release for Deployment

**Status:** Accepted **Date:** 2025-01-09 **Context:** Need to package the
application for deployment.

**Decision:** Use Mix releases to create standalone executable

**Consequences:**

- **Pros:**
  - Self-contained deployment
  - No need for Elixir installation on target machine
  - Includes all dependencies
  - Easy to distribute
  - Works on Unix and Windows
- **Cons:**
  - Larger binary size
  - Platform-specific builds

**Alternatives Considered:**

- Docker container: Could be used in addition to releases
- Source deployment: Requires Elixir runtime on target
