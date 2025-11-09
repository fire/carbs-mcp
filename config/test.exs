import Config

# Don't start the application during tests
config :carbs_mcp, :start_application, false

# Configure your database for tests
config :carbs_mcp, CarbsMCP.Repo,
  database: Path.expand("../priv/test_carbs_optimizers.db", __DIR__),
  pool_size: 10
