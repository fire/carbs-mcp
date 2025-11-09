# ADR-003: Serialize/Deserialize State for Each Operation

**Status:** Accepted  
**Date:** 2025-01-09  
**Context:** Pythonx doesn't easily persist Python object references across eval calls. Need to manage CARBS instance state.

**Decision:** Serialize CARBS state to base64 string, deserialize for each operation, re-serialize after updates

**Consequences:**
- **Pros:**
  - Works reliably with Pythonx's eval model
  - State can be persisted to database easily
  - No complex object reference management
  - State is always in a serializable format
- **Cons:**
  - Performance overhead (serialization/deserialization on each call)
  - Slightly slower than keeping objects in memory
  - More Python eval calls

**Alternatives Considered:**
- Keep Python objects in memory: Rejected - Pythonx doesn't support this well
- Use a Python registry: Considered but adds complexity
- Process-based Python: Would require IPC overhead

**Note:** The performance impact is acceptable because:
- CARBS operations are typically sequential (suggest → observe → suggest)
- GP model fitting is the bottleneck, not serialization
- State persistence is required anyway for database storage

