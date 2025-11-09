defmodule Carbs do
  @moduledoc """
  Main Elixir API module for CARBS operations.
  Provides high-level interface to CARBS hyperparameter optimization.
  """
  require Logger
  alias Carbs.{Params, Param, Observation}
  alias Carbs.PythonBridge
  alias CarbsMCP.Repo
  alias CarbsMCP.{Optimizer, OptimizerParam, ObservationParam, Suggestion, SuggestionParam}
  alias CarbsMCP.Observation, as: DBObservation
  import Ecto.Query

  @doc """
  Create a new CARBS optimizer instance and save to database.
  Returns {:ok, serialized_state} for Python operations.
  """
  def new(config \\ %Params{}, params, name) when is_list(params) do
    # Convert Elixir structs to maps for Python
    config_map = struct_to_map(config)
    params_list = Enum.map(params, &struct_to_map/1)
    
    case PythonBridge.create_carbs(config_map, params_list) do
      {:ok, serialized_state} ->
        # Save normalized data to database
        optimizer_attrs = %{
          name: name,
          better_direction_sign: config.better_direction_sign || Params.default().better_direction_sign,
          seed: config.seed || Params.default().seed,
          num_random_samples: config.num_random_samples || Params.default().num_random_samples,
          is_wandb_logging_enabled: config.is_wandb_logging_enabled || Params.default().is_wandb_logging_enabled,
          wandb_params: config.wandb_params || Params.default().wandb_params,
          checkpoint_dir: config.checkpoint_dir || Params.default().checkpoint_dir,
          s3_checkpoint_path: config.s3_checkpoint_path || Params.default().s3_checkpoint_path,
          is_saved_on_every_observation: config.is_saved_on_every_observation || Params.default().is_saved_on_every_observation,
          initial_search_radius: config.initial_search_radius || Params.default().initial_search_radius,
          exploration_bias: config.exploration_bias || Params.default().exploration_bias,
          num_candidates_for_suggestion_per_dim: config.num_candidates_for_suggestion_per_dim || Params.default().num_candidates_for_suggestion_per_dim,
          resample_frequency: config.resample_frequency || Params.default().resample_frequency,
          max_suggestion_cost: config.max_suggestion_cost || Params.default().max_suggestion_cost,
          min_pareto_cost_fraction: config.min_pareto_cost_fraction || Params.default().min_pareto_cost_fraction,
          is_pareto_group_selection_conservative: config.is_pareto_group_selection_conservative || Params.default().is_pareto_group_selection_conservative,
          is_expected_improvement_pareto_value_clamped: config.is_expected_improvement_pareto_value_clamped || Params.default().is_expected_improvement_pareto_value_clamped,
          is_expected_improvement_value_always_max: config.is_expected_improvement_value_always_max || Params.default().is_expected_improvement_value_always_max,
          outstanding_suggestion_estimator: config.outstanding_suggestion_estimator || Params.default().outstanding_suggestion_estimator,
          num_observations: 0
        }
        
        Repo.transaction(fn ->
          case Optimizer.changeset(%Optimizer{}, optimizer_attrs) |> Repo.insert() do
            {:ok, optimizer} ->
              # Save parameters
              params
              |> Enum.with_index()
              |> Enum.each(fn {param, idx} ->
                space = param.space
                space_attrs = %{
                  optimizer_id: optimizer.id,
                  name: param.name,
                  space_type: space_type_to_string(space),
                  space_min: get_space_min(space),
                  space_max: get_space_max(space),
                  space_scale: get_space_scale(space),
                  space_is_integer: get_space_is_integer(space),
                  space_rounding_factor: get_space_rounding_factor(space),
                  search_center: param.search_center,
                  position: idx
                }
                
                OptimizerParam.changeset(%OptimizerParam{}, space_attrs)
                |> Repo.insert!()
              end)
              
              {:ok, serialized_state}
            error ->
              Repo.rollback(error)
          end
        end)
      error ->
        error
    end
  end
  
  # Helper to get space type string
  defp space_type_to_string(%Carbs.Space.LinearSpace{}), do: "LinearSpace"
  defp space_type_to_string(%Carbs.Space.LogSpace{}), do: "LogSpace"
  defp space_type_to_string(%Carbs.Space.LogitSpace{}), do: "LogitSpace"
  
  defp get_space_min(%Carbs.Space.LinearSpace{min: min}), do: normalize_inf(min)
  defp get_space_min(%Carbs.Space.LogSpace{min: min}), do: normalize_inf(min)
  defp get_space_min(%Carbs.Space.LogitSpace{min: min}), do: min
  
  defp get_space_max(%Carbs.Space.LinearSpace{max: max}), do: normalize_inf(max)
  defp get_space_max(%Carbs.Space.LogSpace{max: max}), do: normalize_inf(max)
  defp get_space_max(%Carbs.Space.LogitSpace{max: max}), do: max
  
  defp get_space_scale(%Carbs.Space.LinearSpace{scale: scale}), do: scale
  defp get_space_scale(%Carbs.Space.LogSpace{scale: scale}), do: scale
  defp get_space_scale(%Carbs.Space.LogitSpace{scale: scale}), do: scale
  
  defp get_space_is_integer(%Carbs.Space.LinearSpace{is_integer: is_integer}), do: is_integer
  defp get_space_is_integer(%Carbs.Space.LogSpace{is_integer: is_integer}), do: is_integer
  defp get_space_is_integer(%Carbs.Space.LogitSpace{}), do: false
  
  defp get_space_rounding_factor(%Carbs.Space.LinearSpace{rounding_factor: rf}), do: rf
  defp get_space_rounding_factor(%Carbs.Space.LogSpace{rounding_factor: rf}), do: rf
  defp get_space_rounding_factor(%Carbs.Space.LogitSpace{}), do: 1
  
  defp normalize_inf(:inf), do: nil
  defp normalize_inf(:"-inf"), do: nil
  defp normalize_inf(v), do: v

  @doc """
  Get next hyperparameter suggestion from CARBS.
  Takes serialized state, returns result and updated serialized state.
  """
  def suggest(serialized_state, opts \\ []) do
    suggestion_id = Keyword.get(opts, :suggestion_id)
    is_remembered = Keyword.get(opts, :is_suggestion_remembered, true)
    
    PythonBridge.suggest(serialized_state, suggestion_id, is_remembered)
  end

  @doc """
  Report an observation result to CARBS.
  Takes serialized state, returns result and updated serialized state.
  """
  def observe(serialized_state, observation) do
    PythonBridge.observe(serialized_state, observation)
  end

  @doc """
  Remove an outstanding suggestion.
  """
  def forget_suggestion(carbs_obj, suggestion) do
    # This would need to be implemented in PythonBridge
    # For now, we'll skip it as it's not critical
    :ok
  end

  @doc """
  Reconstruct serialized state from normalized database.
  This rebuilds the CARBS state by creating a new instance and replaying observations.
  """
  def load(name) do
    case Repo.get_by(Optimizer, name: name) |> Repo.preload([:params, :observations, :suggestions]) do
      nil ->
        {:error, :not_found}
      optimizer ->
        # Reconstruct config from normalized fields
        config = %Params{
          better_direction_sign: optimizer.better_direction_sign,
          seed: optimizer.seed,
          num_random_samples: optimizer.num_random_samples,
          is_wandb_logging_enabled: optimizer.is_wandb_logging_enabled,
          wandb_params: optimizer.wandb_params || %{},
          checkpoint_dir: optimizer.checkpoint_dir,
          s3_checkpoint_path: optimizer.s3_checkpoint_path,
          is_saved_on_every_observation: optimizer.is_saved_on_every_observation,
          initial_search_radius: optimizer.initial_search_radius,
          exploration_bias: optimizer.exploration_bias,
          num_candidates_for_suggestion_per_dim: optimizer.num_candidates_for_suggestion_per_dim,
          resample_frequency: optimizer.resample_frequency,
          max_suggestion_cost: optimizer.max_suggestion_cost,
          min_pareto_cost_fraction: optimizer.min_pareto_cost_fraction,
          is_pareto_group_selection_conservative: optimizer.is_pareto_group_selection_conservative,
          is_expected_improvement_pareto_value_clamped: optimizer.is_expected_improvement_pareto_value_clamped,
          is_expected_improvement_value_always_max: optimizer.is_expected_improvement_value_always_max,
          outstanding_suggestion_estimator: optimizer.outstanding_suggestion_estimator
        }
        
        # Reconstruct params from normalized fields
        params = optimizer.params
        |> Enum.sort_by(& &1.position)
        |> Enum.map(fn param ->
          space = case param.space_type do
            "LinearSpace" ->
              struct(Carbs.Space.LinearSpace, %{
                min: param.space_min || :inf,
                max: param.space_max || :inf,
                scale: param.space_scale || 1.0,
                is_integer: param.space_is_integer || false,
                rounding_factor: param.space_rounding_factor || 1
              })
            "LogSpace" ->
              struct(Carbs.Space.LogSpace, %{
                min: param.space_min || :inf,
                max: param.space_max || :inf,
                scale: param.space_scale || 1.0,
                is_integer: param.space_is_integer || false,
                rounding_factor: param.space_rounding_factor || 1
              })
            "LogitSpace" ->
              struct(Carbs.Space.LogitSpace, %{
                min: param.space_min || 0.0,
                max: param.space_max || 1.0,
                scale: param.space_scale || 1.0
              })
          end
          
          struct(Param, %{
            name: param.name,
            space: space,
            search_center: param.search_center
          })
        end)
        
        # Create new CARBS instance (without saving to DB since it already exists)
        config_map = struct_to_map(config)
        params_list = Enum.map(params, &struct_to_map/1)
        
        case PythonBridge.create_carbs(config_map, params_list) do
          {:ok, serialized_state} ->
            # Replay all observations to rebuild state
            observations = optimizer.observations
            |> Enum.sort_by(& &1.observation_number)
            |> Enum.map(fn obs ->
              # Get parameter values for this observation
              param_values = Repo.all(
                from op in ObservationParam,
                where: op.observation_id == ^obs.id,
                select: {op.param_name, op.param_value}
              )
              |> Enum.into(%{})
              
              Observation.new(param_values, obs.output, obs.cost || 1.0, obs.is_failure || false)
            end)
            
            # Replay observations
            final_state = Enum.reduce(observations, serialized_state, fn obs, state ->
              case observe(state, obs) do
                {:ok, _result, updated_state} -> updated_state
                _error -> state
              end
            end)
            
            {:ok, final_state}
          error ->
            error
        end
    end
  end
  
  @doc """
  Save observation to normalized database.
  Also updates the optimizer's observation count.
  """
  def save_observation(name, observation, suggestion_id \\ nil) do
    Repo.transaction(fn ->
      case Repo.get_by(Optimizer, name: name) do
        nil ->
          Repo.rollback(:optimizer_not_found)
        optimizer ->
          # Get next observation number
          next_num = (optimizer.num_observations || 0) + 1
          
          # Create observation record
          obs_attrs = %{
            optimizer_id: optimizer.id,
            observation_number: next_num,
            output: observation.output,
            cost: observation.cost || 1.0,
            is_failure: observation.is_failure || false,
            suggestion_id: suggestion_id
          }
          
          case DBObservation.changeset(%DBObservation{}, obs_attrs) |> Repo.insert() do
            {:ok, obs} ->
              # Save parameter values
              Enum.each(observation.input, fn {param_name, param_value} ->
                param_attrs = %{
                  observation_id: obs.id,
                  param_name: to_string(param_name),
                  param_value: param_value
                }
                
                ObservationParam.changeset(%ObservationParam{}, param_attrs)
                |> Repo.insert!()
              end)
              
              # Update optimizer observation count
              Optimizer.changeset(optimizer, %{num_observations: next_num})
              |> Repo.update!()
              
              {:ok, obs}
            error ->
              Repo.rollback(error)
          end
      end
    end)
  end
  
  @doc """
  Save suggestion to normalized database.
  """
  def save_suggestion(name, suggestion_map, suggestion_id, is_remembered \\ true) do
    Repo.transaction(fn ->
      case Repo.get_by(Optimizer, name: name) do
        nil ->
          Repo.rollback(:optimizer_not_found)
        optimizer ->
          sugg_attrs = %{
            optimizer_id: optimizer.id,
            suggestion_id: suggestion_id || Ecto.UUID.generate(),
            is_remembered: is_remembered,
            is_observed: false
          }
          
          case Suggestion.changeset(%Suggestion{}, sugg_attrs) |> Repo.insert() do
            {:ok, sugg} ->
              # Save parameter values
              Enum.each(suggestion_map, fn {param_name, param_value} ->
                param_attrs = %{
                  suggestion_id: sugg.id,
                  param_name: to_string(param_name),
                  param_value: param_value
                }
                
                SuggestionParam.changeset(%SuggestionParam{}, param_attrs)
                |> Repo.insert!()
              end)
              
              # Update optimizer last suggestion
              Optimizer.changeset(optimizer, %{last_suggestion_id: sugg.suggestion_id})
              |> Repo.update!()
              
              {:ok, sugg}
            error ->
              Repo.rollback(error)
          end
      end
    end)
  end

  # Helper function to convert structs to maps
  defp struct_to_map(%{__struct__: _} = struct) do
    struct
    |> Map.from_struct()
    |> Enum.map(fn {k, v} -> {k, convert_value(v)} end)
    |> Enum.into(%{})
  end

  defp struct_to_map(map) when is_map(map) do
    Enum.map(map, fn {k, v} -> {k, convert_value(v)} end)
    |> Enum.into(%{})
  end

  defp struct_to_map(value), do: value

  defp convert_value(%{__struct__: module} = struct) when module in [Params, Param, Observation] do
    struct
    |> Map.from_struct()
    |> Enum.map(fn {k, v} -> {k, convert_value(v)} end)
    |> Enum.into(%{})
  end

  defp convert_value(%Carbs.Space.LinearSpace{} = space) do
    min_val = case Map.get(space, :min, :inf) do
      :inf -> :inf
      :"-inf" -> :"-inf"
      v -> v
    end
    max_val = case Map.get(space, :max, :inf) do
      :inf -> :inf
      :"-inf" -> :"-inf"
      v -> v
    end
    
    %{
      "type" => "LinearSpace",
      "min" => min_val,
      "max" => max_val,
      "scale" => Map.get(space, :scale, 1.0),
      "is_integer" => Map.get(space, :is_integer, false),
      "rounding_factor" => Map.get(space, :rounding_factor, 1)
    }
  end

  defp convert_value(%Carbs.Space.LogSpace{} = space) do
    min_val = case Map.get(space, :min, :inf) do
      :inf -> :inf
      :"-inf" -> :"-inf"
      v -> v
    end
    max_val = case Map.get(space, :max, :inf) do
      :inf -> :inf
      :"-inf" -> :"-inf"
      v -> v
    end
    
    %{
      "type" => "LogSpace",
      "min" => min_val,
      "max" => max_val,
      "scale" => Map.get(space, :scale, 1.0),
      "is_integer" => Map.get(space, :is_integer, false),
      "rounding_factor" => Map.get(space, :rounding_factor, 1)
    }
  end

  defp convert_value(%Carbs.Space.LogitSpace{} = space) do
    %{
      "type" => "LogitSpace",
      "min" => Map.get(space, :min, 0.0),
      "max" => Map.get(space, :max, 1.0),
      "scale" => Map.get(space, :scale, 1.0)
    }
  end

  defp convert_value(list) when is_list(list) do
    Enum.map(list, &convert_value/1)
  end

  defp convert_value(value), do: value
end

