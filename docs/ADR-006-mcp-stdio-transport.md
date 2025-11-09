# ADR-006: MCP Stdio Transport

**Status:** Accepted  
**Date:** 2025-01-09  
**Context:** Need to choose transport mechanism for MCP server.

**Decision:** Use stdio transport for MCP communication

**Consequences:**
- **Pros:**
  - Simple integration with MCP clients
  - Standard for command-line tools
  - No network configuration needed
  - Works well with Mix releases
  - Process-based communication (reliable)
- **Cons:**
  - Single client connection
  - No HTTP/SSE support
  - Less flexible than HTTP transport

**Alternatives Considered:**
- HTTP/SSE transport: Considered but stdio is standard for MCP tools
- WebSocket: Overkill for this use case
- Native BEAM: Only for Elixir-to-Elixir communication

