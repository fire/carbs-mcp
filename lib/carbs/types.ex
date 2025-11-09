defmodule Carbs.Params do
  @moduledoc """
  Configuration parameters for CARBS optimizer.
  """
  defstruct [
    :better_direction_sign,
    :seed,
    :num_random_samples,
    :is_wandb_logging_enabled,
    :wandb_params,
    :checkpoint_dir,
    :s3_checkpoint_path,
    :is_saved_on_every_observation,
    :initial_search_radius,
    :exploration_bias,
    :num_candidates_for_suggestion_per_dim,
    :resample_frequency,
    :max_suggestion_cost,
    :min_pareto_cost_fraction,
    :is_pareto_group_selection_conservative,
    :is_expected_improvement_pareto_value_clamped,
    :is_expected_improvement_value_always_max,
    :outstanding_suggestion_estimator
  ]

  @type t :: %__MODULE__{
    better_direction_sign: integer(),
    seed: integer(),
    num_random_samples: integer(),
    is_wandb_logging_enabled: boolean(),
    wandb_params: map(),
    checkpoint_dir: String.t(),
    s3_checkpoint_path: String.t(),
    is_saved_on_every_observation: boolean(),
    initial_search_radius: float(),
    exploration_bias: float(),
    num_candidates_for_suggestion_per_dim: integer(),
    resample_frequency: integer(),
    max_suggestion_cost: float() | nil,
    min_pareto_cost_fraction: float(),
    is_pareto_group_selection_conservative: boolean(),
    is_expected_improvement_pareto_value_clamped: boolean(),
    is_expected_improvement_value_always_max: boolean(),
    outstanding_suggestion_estimator: String.t()
  }

  def default do
    %__MODULE__{
      better_direction_sign: 1,
      seed: 0,
      num_random_samples: 4,
      is_wandb_logging_enabled: false,
      wandb_params: %{},
      checkpoint_dir: "checkpoints/",
      s3_checkpoint_path: "s3://int8/checkpoints",
      is_saved_on_every_observation: true,
      initial_search_radius: 0.3,
      exploration_bias: 1.0,
      num_candidates_for_suggestion_per_dim: 100,
      resample_frequency: 5,
      max_suggestion_cost: nil,
      min_pareto_cost_fraction: 0.2,
      is_pareto_group_selection_conservative: true,
      is_expected_improvement_pareto_value_clamped: true,
      is_expected_improvement_value_always_max: false,
      outstanding_suggestion_estimator: "THOMPSON"
    }
  end
end

defmodule Carbs.Param do
  @moduledoc """
  Parameter definition for CARBS search space.
  """
  defstruct [:name, :space, :search_center]

  @type t :: %__MODULE__{
    name: String.t(),
    space: Carbs.Space.t(),
    search_center: number()
  }
end

defmodule Carbs.Space do
  @moduledoc """
  Parameter space types for CARBS.
  """
  defmodule LinearSpace do
    defstruct [:min, :max, :scale, :is_integer, :rounding_factor]

    @type t :: %__MODULE__{
      min: float(),
      max: float(),
      scale: float(),
      is_integer: boolean(),
      rounding_factor: integer()
    }
  end

  defmodule LogSpace do
    defstruct [:min, :max, :scale, :is_integer, :rounding_factor]

    @type t :: %__MODULE__{
      min: float(),
      max: float(),
      scale: float(),
      is_integer: boolean(),
      rounding_factor: integer()
    }
  end

  defmodule LogitSpace do
    defstruct [:min, :max, :scale]

    @type t :: %__MODULE__{
      min: float(),
      max: float(),
      scale: float()
    }
  end

  @type t :: LinearSpace.t() | LogSpace.t() | LogitSpace.t()
end

defmodule Carbs.Observation do
  @moduledoc """
  Observation input structure for CARBS.
  """
  defstruct [:input, :output, :cost, :is_failure]

  @type t :: %__MODULE__{
    input: map(),
    output: float(),
    cost: float(),
    is_failure: boolean()
  }

  def new(input, output, cost \\ 1.0, is_failure \\ false) do
    %__MODULE__{
      input: input,
      output: output,
      cost: cost,
      is_failure: is_failure
    }
  end
end

