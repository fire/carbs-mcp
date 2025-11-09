# Using CARBS MCP Server with AI Agents

This document describes how to use the CARBS MCP Server with AI agents and MCP-compatible clients.

## Overview

The CARBS MCP Server exposes hyperparameter optimization capabilities through the Model Context Protocol (MCP), making it accessible to AI agents that support MCP.

## MCP Client Configuration

### Claude Desktop

Add to your Claude Desktop MCP configuration file (typically `~/Library/Application Support/Claude/claude_desktop_config.json` on macOS or similar location on Windows):

```json
{
  "mcpServers": {
    "carbs": {
      "command": "/path/to/carbs_mcp/_build/prod/rel/carbs_mcp/bin/carbs_mcp",
      "args": ["start"]
    }
  }
}
```

### Other MCP Clients

The server communicates via stdio using JSON-RPC. Any MCP-compatible client can connect by:

1. Starting the server process
2. Communicating via stdin/stdout
3. Sending JSON-RPC requests
4. Receiving JSON-RPC responses

## Available Tools

### carbs_create

Create a new CARBS optimizer instance.

**Arguments:**
- `name` (string, required): Unique identifier for the optimizer
- `config` (object, optional): CARBS configuration parameters
- `params` (array, required): List of parameters to optimize

**Example:**
```json
{
  "tool": "carbs_create",
  "arguments": {
    "name": "my_experiment",
    "config": {
      "better_direction_sign": -1,
      "is_wandb_logging_enabled": false
    },
    "params": [
      {
        "name": "learning_rate",
        "space": {
          "type": "LogSpace",
          "scale": 0.5
        },
        "search_center": 0.0001
      },
      {
        "name": "batch_size",
        "space": {
          "type": "LinearSpace",
          "scale": 32.0,
          "is_integer": true
        },
        "search_center": 64
      }
    ]
  }
}
```

### carbs_suggest

Get the next hyperparameter suggestion from CARBS.

**Arguments:**
- `name` (string, required): Name of the optimizer

**Example:**
```json
{
  "tool": "carbs_suggest",
  "arguments": {
    "name": "my_experiment"
  }
}
```

**Response:**
```json
{
  "content": [
    {
      "type": "text",
      "text": "Suggestion: {\"learning_rate\":0.00015,\"batch_size\":72}"
    }
  ]
}
```

### carbs_observe

Report an observation result to CARBS.

**Arguments:**
- `name` (string, required): Name of the optimizer
- `input` (object, required): The hyperparameters that were tested
- `output` (number, required): The metric value (what we're optimizing)
- `cost` (number, optional): Cost in seconds (default: 1.0)
- `is_failure` (boolean, optional): Whether the run failed (default: false)

**Example:**
```json
{
  "tool": "carbs_observe",
  "arguments": {
    "name": "my_experiment",
    "input": {
      "learning_rate": 0.00015,
      "batch_size": 72
    },
    "output": 0.95,
    "cost": 120.5,
    "is_failure": false
  }
}
```

### carbs_load

Load an optimizer from the database (verifies it exists).

**Arguments:**
- `name` (string, required): Name of the optimizer

### carbs_save

Explicitly save an optimizer to the database.

**Arguments:**
- `name` (string, required): Name of the optimizer

### carbs_list

List all saved optimizers.

**Arguments:** None

**Example Response:**
```json
{
  "content": [
    {
      "type": "text",
      "text": "Saved optimizers: my_experiment, another_experiment"
    }
  ]
}
```

## Typical Workflow

1. **Create Optimizer**: Use `carbs_create` to set up a new optimization run
2. **Get Suggestions**: Use `carbs_suggest` to get hyperparameters to test
3. **Run Experiment**: Execute your training/evaluation with the suggested parameters
4. **Report Results**: Use `carbs_observe` to report the outcome
5. **Repeat**: Continue steps 2-4 until satisfied with results

## Example Agent Interaction

```
Agent: "I want to optimize hyperparameters for my model"

Agent calls: carbs_create
  → Creates optimizer "model_tuning"

Agent calls: carbs_suggest
  → Gets: {"learning_rate": 0.001, "batch_size": 32}

Agent: "I'll test these parameters"
  → Runs training with suggested params
  → Measures validation accuracy: 0.92
  → Measures training time: 180 seconds

Agent calls: carbs_observe
  → Reports: input={...}, output=0.92, cost=180

Agent calls: carbs_suggest (again)
  → Gets new suggestion based on previous observation
  → Continues optimization...
```

## Space Types

### LogSpace
For parameters that vary logarithmically (e.g., learning rates, regularization).

**Properties:**
- `type`: "LogSpace"
- `scale` (number): Scale factor for the space
- `min` (number, optional): Minimum value
- `max` (number, optional): Maximum value
- `is_integer` (boolean, optional): Whether to round to integers
- `rounding_factor` (integer, optional): Round to nearest multiple

### LinearSpace
For parameters that vary linearly (e.g., batch sizes, layer counts).

**Properties:**
- `type`: "LinearSpace"
- `scale` (number): Scale factor (should be >3 for integer spaces)
- `min` (number, optional): Minimum value
- `max` (number, optional): Maximum value
- `is_integer` (boolean, optional): Whether to round to integers
- `rounding_factor` (integer, optional): Round to nearest multiple

### LogitSpace
For parameters that should be between 0 and 1 (e.g., dropout rates).

**Properties:**
- `type`: "LogitSpace"
- `scale` (number): Scale factor
- `min` (number, optional): Minimum value (default: 0.0)
- `max` (number, optional): Maximum value (default: 1.0)

## Configuration Options

When creating an optimizer, you can configure:

- `better_direction_sign`: `1` to maximize, `-1` to minimize (default: 1)
- `is_wandb_logging_enabled`: Enable Weights & Biases logging (default: false)
- `max_suggestion_cost`: Soft limit on suggestion cost (default: null)
- `num_random_samples`: Random samples before Bayesian optimization (default: 4)
- `resample_frequency`: Resample pareto points every N observations (default: 5, set to 0 to disable)

## Error Handling

The server returns MCP-compliant error responses for:
- Missing required arguments
- Invalid parameter configurations
- Database errors
- Python/CARBS errors

All errors include descriptive messages to help diagnose issues.

## Best Practices

1. **Start with low-cost parameters**: CARBS explores higher-cost regions later
2. **Report failures accurately**: Use `is_failure=true` for parameter-caused failures
3. **Use appropriate space types**: LogSpace for scale parameters, LinearSpace for counts
4. **Set reasonable scales**: For integer LinearSpace, use scale >3
5. **Monitor pareto front**: CARBS optimizes the cost-performance tradeoff

## Troubleshooting

**"Failed to initialize Python"**
- Ensure Python 3.8+ is installed
- Check that CARBS path is correct in config
- Verify Python dependencies are installed

**"Failed to create optimizer"**
- Check parameter definitions are valid
- Ensure space types are correct
- Verify search_center values are reasonable

**"Failed to load optimizer"**
- Check optimizer name exists (use `carbs_list`)
- Verify database is accessible
- Check database file permissions

