defmodule CarbsTest do
  use ExUnit.Case
  doctest Carbs

  alias Carbs
  alias Carbs.{Params, Param, Observation}
  alias Carbs.Space

  test "creates a new CARBS optimizer" do
    config = %Params{
      better_direction_sign: -1,
      is_wandb_logging_enabled: false
    }

    params = [
      %Param{
        name: "learning_rate",
        space: %Space.LogSpace{scale: 0.5},
        search_center: 0.0001
      }
    ]

    case Carbs.new(config, params) do
      {:ok, serialized_state} ->
        assert is_binary(serialized_state)
        assert byte_size(serialized_state) > 0
      error ->
        flunk("Failed to create CARBS optimizer: #{inspect(error)}")
    end
  end

  test "suggest and observe cycle" do
    config = %Params{
      better_direction_sign: -1,
      is_wandb_logging_enabled: false
    }

    params = [
      %Param{
        name: "learning_rate",
        space: %Space.LogSpace{scale: 0.5},
        search_center: 0.0001
      }
    ]

    # Create optimizer
    {:ok, serialized_state} = Carbs.new(config, params)

    # Get suggestion
    case Carbs.suggest(serialized_state) do
      {:ok, result, updated_state} ->
        suggestion = Map.get(result, "suggestion", %{})
        assert Map.has_key?(suggestion, "learning_rate")

        # Observe result
        observation = Observation.new(
          suggestion,
          0.95,
          10.0,
          false
        )

        case Carbs.observe(updated_state, observation) do
          {:ok, _obs_result, _final_state} ->
            assert true
          error ->
            flunk("Failed to observe: #{inspect(error)}")
        end
      error ->
        flunk("Failed to suggest: #{inspect(error)}")
    end
  end
end

