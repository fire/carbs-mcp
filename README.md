# CARBS MCP Server

A Model Context Protocol (MCP) stdio server that exposes CARBS (Cost Aware pareto-Region Bayesian Search) hyperparameter optimization capabilities.

## Overview

This project integrates the Python CARBS library with Elixir using Pythonx, providing a standalone MCP server that can be used by MCP-compatible clients for hyperparameter optimization.

## Features

- **MCP Protocol**: Full MCP server implementation using ex_mcp
- **Multiple Transports**: Supports stdio (default), HTTP, and streaming HTTP (SSE)
- **Python Integration**: Uses Pythonx to embed Python and call CARBS library
- **State Persistence**: SQLite3 database via Ecto with ETNF-normalized schema
- **Mix Release**: Packaged as a standalone release for deployment

## Installation

1. Ensure you have Elixir and Python 3.8+ installed
2. Install dependencies:
   ```bash
   mix deps.get
   ```
3. Set up the database:
   ```bash
   mix ecto.create
   mix ecto.migrate
   ```

## Building a Release

```bash
MIX_ENV=prod mix release
```

The release will be in `_build/prod/rel/carbs_mcp/`.

## Running the Server

### Stdio Transport (Default)

```bash
_build/prod/rel/carbs_mcp/bin/carbs_mcp start
```

Or for foreground mode:
```bash
_build/prod/rel/carbs_mcp/bin/carbs_mcp start_iex
```

### HTTP Transport

Set the transport type and start the server:

```bash
MCP_TRANSPORT=http _build/prod/rel/carbs_mcp/bin/carbs_mcp start
```

The server will listen on port 8080 (configurable) for HTTP requests.

### Streaming HTTP (SSE) Transport

```bash
MCP_TRANSPORT=sse _build/prod/rel/carbs_mcp/bin/carbs_mcp start
```

The server will provide Server-Sent Events on `/mcp/stream` endpoint.

## MCP Tools

The server exposes the following tools:

- `carbs_create` - Create a new CARBS optimizer instance
- `carbs_suggest` - Get next hyperparameter suggestion
- `carbs_observe` - Report an observation result
- `carbs_load` - Load an optimizer from the database
- `carbs_save` - Save an optimizer to the database
- `carbs_list` - List all saved optimizers

## Configuration

Python dependencies are configured in `config/config.exs` via Pythonx's `pyproject_toml` configuration.

Database configuration is in `config/config.exs` - by default uses SQLite3 at `priv/carbs_optimizers.db`.

MCP transport can be configured:
- Default: `:stdio` transport
- HTTP: Set `config :carbs_mcp, :mcp_transport, :http` and configure port/host
- SSE: Set `config :carbs_mcp, :mcp_transport, :sse` and configure port/host
- Or use environment variable: `MCP_TRANSPORT=http` or `MCP_TRANSPORT=sse`

## Development

Run tests:
```bash
mix test
```

## License

See LICENSE file.

