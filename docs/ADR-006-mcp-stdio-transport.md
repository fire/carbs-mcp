# ADR-006: MCP Transport Support

**Status:** Accepted  
**Date:** 2025-01-09  
**Last Updated:** 2025-01-09  
**Context:** Need to choose transport mechanism(s) for MCP server.

**Decision:** Support multiple MCP transports: stdio (default), HTTP, and streaming HTTP (SSE)

**Consequences:**
- **Pros:**
  - Flexibility to use appropriate transport for deployment scenario
  - Stdio: Simple for command-line tools, no network config
  - HTTP: Standard REST API, easy to integrate with web services
  - Streaming HTTP (SSE): Real-time updates, better for long-running operations
  - Works well with Mix releases
  - Can support multiple clients with HTTP transports
- **Cons:**
  - More complex configuration
  - Need to handle different transport types
  - HTTP requires network configuration
  - SSE requires connection management

**Transport Details:**

1. **Stdio Transport (Default)**
   - Process-based communication via stdin/stdout
   - Single client connection
   - Standard for MCP command-line tools
   - No network configuration needed
   - Best for: Local development, Claude Desktop integration

2. **HTTP Transport**
   - RESTful API over HTTP
   - Multiple client support
   - Standard HTTP methods (POST for requests)
   - Best for: Web services, API integrations, microservices

3. **Streaming HTTP (SSE)**
   - Server-Sent Events for real-time updates
   - Long-lived connections
   - Event streaming for progress updates
   - Best for: Long-running optimizations, real-time monitoring

**Implementation:**
- Transport type configurable via application environment
- Default to stdio for backward compatibility
- ex_mcp library supports all three transport types
- Handler implementation (CarbsMCP.Server) is transport-agnostic

**Alternatives Considered:**
- Stdio only: Rejected - too limiting for different deployment scenarios
- HTTP only: Rejected - stdio is standard for MCP tools
- WebSocket: Considered but SSE is simpler and sufficient for server-to-client streaming
- Native BEAM: Only for Elixir-to-Elixir communication

