# ADR-005: Use ex_mcp for MCP Implementation

**Status:** Accepted **Date:** 2025-01-09 **Context:** Need to implement MCP
stdio server. Options include ex_mcp library or implementing from scratch.

**Decision:** Use ex_mcp library from GitHub
(https://github.com/azmaveth/ex_mcp)

**Consequences:**

- **Pros:**
  - Full MCP protocol implementation
  - Production-ready (v0.6.0)
  - 100% MCP compliant
  - Well-tested (500+ tests)
  - Supports multiple transports (stdio, HTTP, streaming HTTP/SSE)
  - Active development
  - Transport-agnostic handler API
- **Cons:**
  - External dependency (GitHub, not Hex)
  - API may change
  - Less documentation than established libraries

**Alternatives Considered:**

- Hermes MCP: Considered but ex_mcp appears more actively maintained
- Implement from scratch: Rejected - too much work, error-prone
- Use MCP spec directly: Rejected - would require implementing entire protocol
