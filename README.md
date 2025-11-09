# CARBS MCP Server

A Model Context Protocol (MCP) stdio server that exposes CARBS (Cost Aware pareto-Region Bayesian Search) hyperparameter optimization capabilities.

## Overview

This project integrates the Python CARBS library with Elixir using Pythonx, providing a standalone MCP server that can be used by MCP-compatible clients for hyperparameter optimization.

## Features

- **MCP Protocol**: Full MCP stdio server implementation using ex_mcp
- **Python Integration**: Uses Pythonx to embed Python and call CARBS library
- **State Persistence**: SQLite3 database via Ecto for storing optimizer state
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

```bash
_build/prod/rel/carbs_mcp/bin/carbs_mcp start
```

Or for foreground mode:
```bash
_build/prod/rel/carbs_mcp/bin/carbs_mcp start_iex
```

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

## Development

Run tests:
```bash
mix test
```

## License

See LICENSE file.

