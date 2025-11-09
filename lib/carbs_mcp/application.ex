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

    children =
      [
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
    # Determine transport type from config or environment
    transport = get_transport_type()

    case transport do
      :stdio ->
        start_stdio_transport()

      :http ->
        start_http_transport()

      :sse ->
        start_sse_transport()

      other ->
        Logger.error("Unknown transport type: #{inspect(other)}, defaulting to stdio")
        start_stdio_transport()
    end
  end

  defp get_transport_type do
    # Check environment variable first, then config
    case System.get_env("MCP_TRANSPORT") do
      "http" -> :http
      "sse" -> :sse
      "stdio" -> :stdio
      _ -> Application.get_env(:carbs_mcp, :mcp_transport, :stdio)
    end
  end

  defp start_stdio_transport do
    # Start MCP stdio server
    case Code.ensure_loaded(ExMCP.Transport.Stdio) do
      {:module, _} ->
        {ExMCP.Transport.Stdio, handler: CarbsMCP.Server}

      {:error, _} ->
        Logger.warn("ExMCP.Transport.Stdio not found, trying alternative...")

        case Code.ensure_loaded(ExMCP.Server) do
          {:module, _} ->
            {ExMCP.Server, transport: :stdio, handler: CarbsMCP.Server}

          {:error, _} ->
            Logger.error("Could not find ExMCP stdio transport module")
            nil
        end
    end
  end

  defp start_http_transport do
    # Start MCP HTTP server
    port = Application.get_env(:carbs_mcp, :mcp_http_port, 8080)
    host = Application.get_env(:carbs_mcp, :mcp_http_host, "0.0.0.0")

    case Code.ensure_loaded(ExMCP.Transport.HTTP) do
      {:module, _} ->
        {ExMCP.Transport.HTTP, handler: CarbsMCP.Server, port: port, host: host}

      {:error, _} ->
        Logger.warn("ExMCP.Transport.HTTP not found, trying alternative...")

        case Code.ensure_loaded(ExMCP.Server) do
          {:module, _} ->
            {ExMCP.Server, transport: :http, handler: CarbsMCP.Server, port: port, host: host}

          {:error, _} ->
            Logger.error("Could not find ExMCP HTTP transport module, falling back to stdio")
            start_stdio_transport()
        end
    end
  end

  defp start_sse_transport do
    # Start MCP SSE (streaming HTTP) server
    port = Application.get_env(:carbs_mcp, :mcp_http_port, 8080)
    host = Application.get_env(:carbs_mcp, :mcp_http_host, "0.0.0.0")

    case Code.ensure_loaded(ExMCP.Transport.SSE) do
      {:module, _} ->
        {ExMCP.Transport.SSE, handler: CarbsMCP.Server, port: port, host: host}

      {:error, _} ->
        Logger.warn("ExMCP.Transport.SSE not found, trying alternative...")

        case Code.ensure_loaded(ExMCP.Server) do
          {:module, _} ->
            {ExMCP.Server, transport: :sse, handler: CarbsMCP.Server, port: port, host: host}

          {:error, _} ->
            Logger.error("Could not find ExMCP SSE transport module, falling back to stdio")
            start_stdio_transport()
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
