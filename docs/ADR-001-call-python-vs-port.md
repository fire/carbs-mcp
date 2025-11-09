# ADR-001: Call Python from Elixir vs Port to Elixir

**Status:** Accepted  
**Date:** 2025-01-09  
**Context:** We needed to integrate CARBS (a ~2,200 line Python library) with Elixir. The options were:
1. Port the entire codebase to Elixir
2. Call the Python code from Elixir

**Decision:** Call Python from Elixir using Pythonx

**Consequences:**
- **Pros:**
  - Fast implementation (2-5 days vs 2-4 months)
  - Leverages existing, well-tested Python code
  - No risk of introducing bugs during porting
  - Can use existing Python ecosystem (PyTorch, Pyro, etc.)
- **Cons:**
  - Requires Python runtime
  - GIL limitations for concurrency
  - Some overhead from interop calls
  - Less "pure" Elixir solution

**Alternatives Considered:**
- Porting to Elixir: Rejected due to time and complexity (GP models, tensor operations, mathematical libraries)
- HTTP service: Rejected due to network overhead and added complexity
- ErlPort/PyCall: Considered but Pythonx provides better integration

