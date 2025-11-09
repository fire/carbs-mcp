import Config

# Configure Pythonx with CARBS dependencies
config :pythonx, :uv_init,
  pyproject_toml: """
  [project]
  name = "carbs_mcp"
  version = "0.1.0"
  requires-python = ">=3.8"
  dependencies = [
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

# Configure CARBS Python library path
# Defaults to ../../../carbs relative to lib/carbs/python_bridge.ex
# Override this if CARBS is installed elsewhere
config :carbs_mcp, :carbs_path, Path.expand("../../../carbs", __DIR__)

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

