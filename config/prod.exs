import Config

# Configure your database for production
config :carbs_mcp, CarbsMCP.Repo,
  database: Path.expand("../priv/carbs_optimizers.db", __DIR__),
  pool_size: 1

