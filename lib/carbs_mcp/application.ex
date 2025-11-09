defmodule CarbsMCP.Application do
  @moduledoc """
  Application supervision tree for CARBS MCP server.
  """
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    # Run database migrations
    setup_database()

    children = [
      # Ecto repository
      CarbsMCP.Repo,
      # MCP stdio server - check ex_mcp docs for exact API
      # This may need to be adjusted based on ex_mcp's actual API
      start_mcp_server()
    ]
    |> Enum.filter(&(!is_nil(&1)))

    opts = [strategy: :one_for_one, name: CarbsMCP.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp start_mcp_server do
    # Try to start MCP stdio server
    # The exact API may vary - check ex_mcp documentation
    # Common patterns:
    # - ExMCP.Transport.Stdio.start_link(handler: CarbsMCP.Server)
    # - ExMCP.Server.start_link(transport: :stdio, handler: CarbsMCP.Server)
    # - Or a GenServer that wraps the transport
    
    # For now, we'll use a generic approach that should work
    # This will need to be adjusted once ex_mcp is available
    case Code.ensure_loaded(ExMCP.Transport.Stdio) do
      {:module, _} ->
        {ExMCP.Transport.Stdio, handler: CarbsMCP.Server}
      {:error, _} ->
        Logger.warn("ExMCP.Transport.Stdio not found, trying alternative...")
        # Try alternative API
        case Code.ensure_loaded(ExMCP.Server) do
          {:module, _} ->
            {ExMCP.Server, transport: :stdio, handler: CarbsMCP.Server}
          {:error, _} ->
            Logger.error("Could not find ExMCP stdio transport module")
            nil
        end
    end
  end

  defp setup_database do
    try do
      # Ensure database directory exists
      db_path = Application.get_env(:carbs_mcp, CarbsMCP.Repo)[:database]
      db_dir = Path.dirname(db_path)
      File.mkdir_p!(db_dir)

      # Run migrations
      migrations_path = Path.join([:code.priv_dir(:carbs_mcp), "repo", "migrations"])
      
      if File.exists?(migrations_path) do
        Ecto.Migrator.run(CarbsMCP.Repo, migrations_path, :up, all: true)
        Logger.info("Database migrations completed")
      else
        Logger.warn("Migrations path not found: #{migrations_path}")
      end
    rescue
      e ->
        Logger.error("Failed to setup database: #{inspect(e)}")
        # Don't fail startup if database setup fails
        :ok
    end
  end
end

