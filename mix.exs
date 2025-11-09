defmodule CarbsMCP.MixProject do
  use Mix.Project

  def project do
    [
      app: :carbs_mcp,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        carbs_mcp: [
          include_executables_for: [:unix, :windows]
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    # In test mode, don't start the application
    if Mix.env() == :test do
      [
        extra_applications: [:logger]
      ]
    else
      [
        extra_applications: [:logger],
        mod: {CarbsMCP.Application, []}
      ]
    end
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:pythonx, "~> 0.4.7"},
      {:ecto, "~> 3.11"},
      {:ecto_sqlite3, "~> 0.12.0"},
      {:ex_mcp, git: "https://github.com/azmaveth/ex_mcp"},
      {:jason, "~> 1.4"}
    ]
  end
end

