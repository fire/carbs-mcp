defmodule CarbsMCP.Optimizer do
  @moduledoc """
  Ecto schema for storing CARBS optimizer state.
  Normalized according to ETNF principles.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "carbs_optimizers" do
    field :name, :string

    # Normalized config fields
    field :better_direction_sign, :integer
    field :seed, :integer
    field :num_random_samples, :integer
    field :is_wandb_logging_enabled, :boolean
    field :wandb_params, :map
    field :checkpoint_dir, :string
    field :s3_checkpoint_path, :string
    field :is_saved_on_every_observation, :boolean
    field :initial_search_radius, :float
    field :exploration_bias, :float
    field :num_candidates_for_suggestion_per_dim, :integer
    field :resample_frequency, :integer
    field :max_suggestion_cost, :float
    field :min_pareto_cost_fraction, :float
    field :is_pareto_group_selection_conservative, :boolean
    field :is_expected_improvement_pareto_value_clamped, :boolean
    field :is_expected_improvement_value_always_max, :boolean
    field :outstanding_suggestion_estimator, :string

    # State tracking
    field :num_observations, :integer
    field :last_suggestion_id, :string

    # Relationships
    has_many :params, CarbsMCP.OptimizerParam
    has_many :observations, CarbsMCP.Observation
    has_many :suggestions, CarbsMCP.Suggestion

    timestamps()
  end

  @doc false
  def changeset(optimizer, attrs) do
    optimizer
    |> cast(attrs, [
      :name,
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
      :outstanding_suggestion_estimator,
      :num_observations,
      :last_suggestion_id
    ])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
