import Config

# Configure your database
config :carbs_mcp, CarbsMCP.Repo,
  database: Path.expand("../priv/carbs_optimizers.db", __DIR__),
  pool_size: 1,
  show_sensitive_data_on_connection_error: true

