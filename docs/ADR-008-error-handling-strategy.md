# ADR-008: Error Handling Strategy

**Status:** Accepted **Date:** 2025-01-09 **Context:** How to handle errors from
Python code and database operations.

**Decision:** Use try/rescue blocks with logging, return error tuples, convert
to MCP error responses

**Consequences:**

- **Pros:**
  - Graceful error handling
  - Errors don't crash the server
  - Useful error messages for debugging
  - MCP-compliant error responses
- **Cons:**
  - More verbose code
  - Need to handle all error cases

**Alternatives Considered:**

- Let it crash (Erlang philosophy): Rejected - MCP server should be resilient
- Return exceptions: Rejected - breaks MCP protocol
