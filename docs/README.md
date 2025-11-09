# Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) for the CARBS MCP Server project.

## What are ADRs?

Architecture Decision Records document important architectural decisions made during the development of the project. Each ADR describes:
- The context and problem
- The decision made
- The consequences (pros and cons)
- Alternatives considered

## ADR Index

- [ADR-001: Call Python from Elixir vs Port to Elixir](./ADR-001-call-python-vs-port.md)
- [ADR-002: Use Pythonx for Python Interop](./ADR-002-use-pythonx.md)
- [ADR-003: Serialize/Deserialize State for Each Operation](./ADR-003-serialize-deserialize-state.md)
- [ADR-004: Use SQLite3 for State Persistence](./ADR-004-use-sqlite3.md)
- [ADR-005: Use ex_mcp for MCP Implementation](./ADR-005-use-ex-mcp.md)
- [ADR-006: MCP Transport Support](./ADR-006-mcp-stdio-transport.md)
- [ADR-007: State Management Strategy](./ADR-007-state-management-strategy.md)
- [ADR-008: Error Handling Strategy](./ADR-008-error-handling-strategy.md)
- [ADR-009: Data Conversion Strategy](./ADR-009-data-conversion-strategy.md)
- [ADR-010: Mix Release for Deployment](./ADR-010-mix-release-deployment.md)
- [ADR-011: ETNF Normalization of Database Schema](./ADR-011-etnf-normalization.md)
- [ADR-012: Testing CARBS with Distribution Playground](./ADR-012-testing-with-distribution-playground.md)

## Summary

The key decisions prioritize:
1. **Speed of implementation** - Calling Python vs porting
2. **Simplicity** - SQLite3, database-only state, multiple transport options
3. **Reliability** - Error handling, state persistence
4. **Standards compliance** - MCP protocol, JSON data format, ETNF normalization
5. **Flexibility** - Support for stdio, HTTP, and streaming HTTP transports

These decisions result in a working implementation that can be deployed quickly while maintaining good performance and reliability characteristics.

