# ADR-004: Use SQLite3 for State Persistence

**Status:** Accepted **Date:** 2025-01-09 **Context:** Need to persist CARBS
optimizer state across server restarts and share between processes.

**Decision:** Use SQLite3 via Ecto for state persistence

**Consequences:**

- **Pros:**
  - Simple deployment (single file database)
  - No separate database server required
  - Good for single-server deployments
  - Easy backups (just copy the .db file)
  - Works well with Mix releases
- **Cons:**
  - Not suitable for distributed/multi-server scenarios
  - Write concurrency limitations
  - File-based (potential I/O bottlenecks)

**Alternatives Considered:**

- PostgreSQL/MySQL: Rejected - adds deployment complexity
- In-memory only: Rejected - need persistence
- File-based (non-SQL): Considered but Ecto provides better tooling
