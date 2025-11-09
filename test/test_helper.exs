ExUnit.start()

# Set up the test database
alias CarbsMCP.Repo

# Ensure database directory exists
db_path = Application.get_env(:carbs_mcp, CarbsMCP.Repo)[:database]
db_dir = Path.dirname(db_path)
File.mkdir_p!(db_dir)

# Start the repo for tests
{:ok, _} = Repo.start_link()

# Run migrations
migrations_path = Path.join([:code.priv_dir(:carbs_mcp), "repo", "migrations"])
Ecto.Migrator.run(Repo, migrations_path, :up, all: true)


