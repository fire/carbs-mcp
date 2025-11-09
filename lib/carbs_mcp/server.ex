defmodule CarbsMCP.Server do
  @moduledoc """
  MCP server implementation for CARBS using ex_mcp.
  Exposes CARBS hyperparameter optimization as MCP tools.
  """
  use ExMCP.Server.Handler

  require Logger
  alias Carbs
  alias Carbs.{Params, Param, Observation}
  alias CarbsMCP.Repo
  alias CarbsMCP.Optimizer

  @impl true
  def init(_args) do
    # Initialize Python environment
    case Carbs.PythonBridge.init() do
      :ok ->
        Logger.info("Python environment initialized")
        {:ok, %{}}

      error ->
        Logger.error("Failed to initialize Python: #{inspect(error)}")
        {:error, error}
    end
  end

  @impl true
  def handle_initialize(_params, state) do
    {:ok,
     %{
       name: "carbs-mcp",
       version: "0.1.0",
       capabilities: %{
         tools: %{}
       }
     }, state}
  end

  @impl true
  def handle_list_tools(_params, state) do
    tools = [
      %{
        name: "carbs_create",
        description: "Create a new CARBS optimizer instance",
        inputSchema: %{
          type: "object",
          properties: %{
            name: %{type: "string", description: "Unique name for the optimizer"},
            config: %{
              type: "object",
              description: "CARBS configuration parameters",
              properties: %{
                better_direction_sign: %{type: "integer", enum: [-1, 1], default: 1},
                is_wandb_logging_enabled: %{type: "boolean", default: false},
                max_suggestion_cost: %{type: "number", nullable: true}
              }
            },
            params: %{
              type: "array",
              description: "List of parameters to optimize",
              items: %{
                type: "object",
                properties: %{
                  name: %{type: "string"},
                  space: %{
                    type: "object",
                    properties: %{
                      type: %{type: "string", enum: ["LinearSpace", "LogSpace", "LogitSpace"]},
                      scale: %{type: "number", default: 1.0},
                      min: %{type: "number", nullable: true},
                      max: %{type: "number", nullable: true},
                      is_integer: %{type: "boolean", default: false}
                    },
                    required: ["type"]
                  },
                  search_center: %{type: "number"}
                },
                required: ["name", "space", "search_center"]
              }
            }
          },
          required: ["name", "params"]
        }
      },
      %{
        name: "carbs_suggest",
        description: "Get next hyperparameter suggestion from CARBS",
        inputSchema: %{
          type: "object",
          properties: %{
            name: %{type: "string", description: "Name of the optimizer"}
          },
          required: ["name"]
        }
      },
      %{
        name: "carbs_observe",
        description: "Report an observation result to CARBS",
        inputSchema: %{
          type: "object",
          properties: %{
            name: %{type: "string", description: "Name of the optimizer"},
            input: %{type: "object", description: "Input parameters that were tested"},
            output: %{type: "number", description: "Output value (metric to optimize)"},
            cost: %{type: "number", description: "Cost (usually time in seconds)", default: 1.0},
            is_failure: %{type: "boolean", description: "Whether the run failed", default: false}
          },
          required: ["name", "input", "output"]
        }
      },
      %{
        name: "carbs_load",
        description: "Load an optimizer from the database",
        inputSchema: %{
          type: "object",
          properties: %{
            name: %{type: "string", description: "Name of the optimizer"}
          },
          required: ["name"]
        }
      },
      %{
        name: "carbs_save",
        description: "Save an optimizer to the database",
        inputSchema: %{
          type: "object",
          properties: %{
            name: %{type: "string", description: "Name of the optimizer"}
          },
          required: ["name"]
        }
      },
      %{
        name: "carbs_list",
        description: "List all saved optimizers",
        inputSchema: %{
          type: "object",
          properties: %{}
        }
      }
    ]

    {:ok, tools, state}
  end

  @impl true
  def handle_call_tool("carbs_create", args, state) do
    name = Map.get(args, "name") || Map.get(args, :name)
    config_map = Map.get(args, "config") || Map.get(args, :config) || %{}
    params_list = Map.get(args, "params") || Map.get(args, :params) || []

    if is_nil(name) or is_nil(params_list) or length(params_list) == 0 do
      content = [
        %{type: "text", text: "Missing required arguments: name and params are required"}
      ]

      {:error, content, state}
    else
      # Convert to Elixir structs
      config =
        struct(Params, Map.merge(Params.default() |> Map.from_struct(), atomize_keys(config_map)))

      # Build params list with error handling
      params_result =
        Enum.reduce_while(params_list, [], fn p, acc ->
          space_map = Map.get(p, "space") || Map.get(p, :space)

          if is_nil(space_map) do
            {:halt, {:error, "Missing space definition for parameter"}}
          else
            space_type = Map.get(space_map, "type") || Map.get(space_map, :type)

            space_result =
              case space_type do
                "LogSpace" ->
                  space_config = atomize_keys(space_map)

                  {:ok,
                   struct(Carbs.Space.LogSpace, %{
                     min: Map.get(space_config, :min, :inf),
                     max: Map.get(space_config, :max, :inf),
                     scale: Map.get(space_config, :scale, 1.0),
                     is_integer: Map.get(space_config, :is_integer, false),
                     rounding_factor: Map.get(space_config, :rounding_factor, 1)
                   })}

                "LinearSpace" ->
                  space_config = atomize_keys(space_map)

                  {:ok,
                   struct(Carbs.Space.LinearSpace, %{
                     min: Map.get(space_config, :min, :inf),
                     max: Map.get(space_config, :max, :inf),
                     scale: Map.get(space_config, :scale, 1.0),
                     is_integer: Map.get(space_config, :is_integer, false),
                     rounding_factor: Map.get(space_config, :rounding_factor, 1)
                   })}

                "LogitSpace" ->
                  space_config = atomize_keys(space_map)

                  {:ok,
                   struct(Carbs.Space.LogitSpace, %{
                     min: Map.get(space_config, :min, 0.0),
                     max: Map.get(space_config, :max, 1.0),
                     scale: Map.get(space_config, :scale, 1.0)
                   })}

                other ->
                  {:error,
                   "Unknown space type: #{inspect(other)}. Must be one of: LogSpace, LinearSpace, LogitSpace"}
              end

            case space_result do
              {:error, error_msg} ->
                {:halt, {:error, error_msg}}

              {:ok, space} ->
                param_name = Map.get(p, "name") || Map.get(p, :name)
                search_center = Map.get(p, "search_center") || Map.get(p, :search_center)

                if is_nil(param_name) or is_nil(search_center) do
                  {:halt, {:error, "Parameter missing required fields: name and search_center"}}
                else
                  param =
                    struct(Param, %{
                      name: param_name,
                      space: space,
                      search_center: search_center
                    })

                  {:cont, [param | acc]}
                end
            end
          end
        end)

      case params_result do
        {:error, error_msg} ->
          content = [%{type: "text", text: error_msg}]
          {:error, content, state}

        params when is_list(params) ->
          params = Enum.reverse(params)

          case Carbs.new(config, params, name) do
            {:ok, _serialized_state} ->
              content = [%{type: "text", text: "Created CARBS optimizer: #{name}"}]
              {:ok, content, state}

            error ->
              content = [%{type: "text", text: "Failed to create optimizer: #{inspect(error)}"}]
              {:error, content, state}
          end
      end
    end
  end

  def handle_call_tool("carbs_suggest", args, state) do
    name = Map.get(args, "name") || Map.get(args, :name)

    if is_nil(name) do
      content = [%{type: "text", text: "Missing required argument: name"}]
      {:error, content, state}
    else
      case Carbs.load(name) do
        {:ok, serialized_state} ->
          case Carbs.suggest(serialized_state) do
            {:ok, result, _updated_state} ->
              suggestion = Map.get(result, "suggestion", %{})
              suggestion_id = Ecto.UUID.generate()

              # Save suggestion to normalized database
              case Carbs.save_suggestion(name, suggestion, suggestion_id) do
                {:ok, _} ->
                  text = "Suggestion: #{Jason.encode!(suggestion)}"
                  content = [%{type: "text", text: text}]
                  {:ok, content, state}

                error ->
                  content = [
                    %{type: "text", text: "Failed to save suggestion: #{inspect(error)}"}
                  ]

                  {:error, content, state}
              end

            error ->
              content = [%{type: "text", text: "Failed to get suggestion: #{inspect(error)}"}]
              {:error, content, state}
          end

        error ->
          content = [%{type: "text", text: "Failed to load optimizer: #{inspect(error)}"}]
          {:error, content, state}
      end
    end
  end

  def handle_call_tool("carbs_observe", args, state) do
    name = Map.get(args, "name") || Map.get(args, :name)
    input = Map.get(args, "input") || Map.get(args, :input)
    output = Map.get(args, "output") || Map.get(args, :output)
    cost = Map.get(args, "cost") || Map.get(args, :cost) || 1.0
    is_failure = Map.get(args, "is_failure") || Map.get(args, :is_failure) || false

    if is_nil(name) or is_nil(input) or is_nil(output) do
      content = [
        %{type: "text", text: "Missing required arguments: name, input, and output are required"}
      ]

      {:error, content, state}
    else
      observation = Observation.new(input, output, cost, is_failure)

      case Carbs.load(name) do
        {:ok, serialized_state} ->
          case Carbs.observe(serialized_state, observation) do
            {:ok, _result, _updated_state} ->
              # Save observation to normalized database
              case Carbs.save_observation(name, observation) do
                {:ok, _} ->
                  content = [%{type: "text", text: "Observation recorded for #{name}"}]
                  {:ok, content, state}

                error ->
                  content = [
                    %{type: "text", text: "Failed to save observation: #{inspect(error)}"}
                  ]

                  {:error, content, state}
              end

            error ->
              content = [%{type: "text", text: "Failed to observe: #{inspect(error)}"}]
              {:error, content, state}
          end

        error ->
          content = [%{type: "text", text: "Failed to load optimizer: #{inspect(error)}"}]
          {:error, content, state}
      end
    end
  end

  def handle_call_tool("carbs_load", args, state) do
    name = Map.get(args, "name") || Map.get(args, :name)

    if is_nil(name) do
      content = [%{type: "text", text: "Missing required argument: name"}]
      {:error, content, state}
    else
      case Carbs.load(name) do
        {:ok, _serialized_state} ->
          content = [%{type: "text", text: "Loaded optimizer: #{name}"}]
          {:ok, content, state}

        error ->
          content = [%{type: "text", text: "Failed to load optimizer: #{inspect(error)}"}]
          {:error, content, state}
      end
    end
  end

  def handle_call_tool("carbs_save", args, state) do
    name = Map.get(args, "name") || Map.get(args, :name)

    if is_nil(name) do
      content = [%{type: "text", text: "Missing required argument: name"}]
      {:error, content, state}
    else
      case Carbs.load(name) do
        {:ok, _serialized_state} ->
          # Optimizer is already saved in normalized form
          # This just verifies it exists
          content = [%{type: "text", text: "Saved optimizer: #{name}"}]
          {:ok, content, state}

        error ->
          content = [%{type: "text", text: "Failed to load optimizer: #{inspect(error)}"}]
          {:error, content, state}
      end
    end
  end

  def handle_call_tool("carbs_list", _args, state) do
    optimizers = Repo.all(Optimizer)
    names = Enum.map(optimizers, & &1.name)
    text = "Saved optimizers: #{Enum.join(names, ", ")}"
    content = [%{type: "text", text: text}]
    {:ok, content, state}
  end

  def handle_call_tool(tool_name, _args, state) do
    content = [%{type: "text", text: "Unknown tool: #{tool_name}"}]
    {:error, content, state}
  end

  # Helper to convert string keys to atom keys
  defp atomize_keys(map) when is_map(map) do
    Enum.reduce(map, %{}, fn {k, v}, acc ->
      new_key =
        case k do
          k when is_binary(k) ->
            # Try to convert to existing atom, fallback to string if not found
            try do
              String.to_existing_atom(k)
            rescue
              ArgumentError ->
                # If atom doesn't exist, try to create it (safe for known keys)
                String.to_atom(k)
            end

          k ->
            k
        end

      Map.put(acc, new_key, atomize_keys(v))
    end)
  end

  defp atomize_keys(list) when is_list(list) do
    Enum.map(list, &atomize_keys/1)
  end

  defp atomize_keys(value), do: value
end
