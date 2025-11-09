defmodule CarbsMCP.Repo do
  @moduledoc """
  Ecto repository for CARBS optimizers.
  """
  use Ecto.Repo,
    otp_app: :carbs_mcp,
    adapter: Ecto.Adapters.SQLite3
end

