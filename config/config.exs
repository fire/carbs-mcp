import Config

# Configure Pythonx with CARBS dependencies via uv project
config :pythonx, :uv_init,
  pyproject_toml: """
  [project]
  name = "carbs_mcp"
  version = "0.1.0"
  requires-python = ">=3.8"
  dependencies = [
    "carbs",
    "torch>=1.8.1",
    "pyro-ppl>=1.6.0",
    "numpy",
    "scikit-learn",
    "attrs",
    "loguru>=0.5.3",
    "cattrs>=1.3.0",
    "seaborn",
    "wandb"
  ]
  """

# Configure Ecto repositories
config :carbs_mcp, ecto_repos: [CarbsMCP.Repo]

# Configure Ecto repository
config :carbs_mcp, CarbsMCP.Repo,
  database: Path.expand("../priv/carbs_optimizers.db", __DIR__),
  pool_size: 1

# Configure MCP transport
# Options: :stdio (default), :http, :sse
# Can be overridden via environment variable MCP_TRANSPORT
config :carbs_mcp, :mcp_transport, :stdio

# HTTP transport configuration (when using :http or :sse)
config :carbs_mcp, :mcp_http_port, 8080
config :carbs_mcp, :mcp_http_host, "0.0.0.0"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
