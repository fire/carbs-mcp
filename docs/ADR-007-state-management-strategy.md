# ADR-007: State Management Strategy

**Status:** Accepted **Date:** 2025-01-09 **Last Updated:** 2025-01-09
**Context:** How to manage CARBS optimizer instances - in-memory cache vs
database-only.

**Decision:** Database-only with lazy loading (no in-memory cache), using
normalized schema

**Consequences:**

- **Pros:**
  - Simple implementation
  - Always consistent with database
  - No cache invalidation issues
  - Works across server restarts
  - Multiple processes can share state
  - Normalized data structure (ETNF compliant)
  - Queryable optimization history
- **Cons:**
  - Database I/O on every operation
  - State reconstruction overhead (rebuild from normalized tables)
  - Slightly slower than in-memory cache
  - More database writes

**Implementation:**

- State stored in normalized tables (see ADR-011)
- Config and params stored as individual columns
- Observations and suggestions stored in separate tables
- State reconstructed from normalized data when loading optimizer
- Serialized Python state only used temporarily during operations

**Alternatives Considered:**

- In-memory cache with periodic saves: Rejected - risk of data loss
- Hybrid approach: Considered but adds complexity
- Process registry: Would require GenServer state management
- Blob storage: Rejected - violates ETNF, see ADR-011

**Note:** The performance impact is minimal because:

- SQLite3 is fast for single-file operations
- State reconstruction is acceptable for infrequent operations
- Operations are not high-frequency (hyperparameter optimization is slow)
- Normalized schema provides significant benefits for data analysis
