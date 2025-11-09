defmodule CarbsMCP.Repo.Migrations.CreateCarbsOptimizers do
  use Ecto.Migration

  def change do
    # Main optimizers table - normalized according to ETNF, no blobs
    create table(:carbs_optimizers) do
      add :name, :string, null: false

      # Normalized config fields
      add :better_direction_sign, :integer, default: 1
      add :seed, :integer, default: 0
      add :num_random_samples, :integer, default: 4
      add :is_wandb_logging_enabled, :boolean, default: false
      add :wandb_params, :map
      add :checkpoint_dir, :string
      add :s3_checkpoint_path, :string
      add :is_saved_on_every_observation, :boolean, default: true
      add :initial_search_radius, :float
      add :exploration_bias, :float, default: 1.0
      add :num_candidates_for_suggestion_per_dim, :integer, default: 100
      add :resample_frequency, :integer, default: 5
      add :max_suggestion_cost, :float
      add :min_pareto_cost_fraction, :float, default: 0.2
      add :is_pareto_group_selection_conservative, :boolean, default: true
      add :is_expected_improvement_pareto_value_clamped, :boolean, default: true
      add :is_expected_improvement_value_always_max, :boolean, default: false
      add :outstanding_suggestion_estimator, :string, default: "THOMPSON"

      # State tracking
      add :num_observations, :integer, default: 0
      add :last_suggestion_id, :string

      timestamps()
    end

    create unique_index(:carbs_optimizers, [:name])

    # Parameters table - normalized entity type
    create table(:carbs_optimizer_params) do
      add :optimizer_id, references(:carbs_optimizers, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :space_type, :string, null: false  # "LinearSpace", "LogSpace", "LogitSpace"
      add :space_min, :float
      add :space_max, :float
      add :space_scale, :float, default: 1.0
      add :space_is_integer, :boolean, default: false
      add :space_rounding_factor, :integer, default: 1
      add :search_center, :float, null: false
      add :position, :integer, null: false  # Order of parameters

      timestamps()
    end

    create index(:carbs_optimizer_params, [:optimizer_id])
    create unique_index(:carbs_optimizer_params, [:optimizer_id, :name])

    # Observations table - normalized entity type
    create table(:carbs_observations) do
      add :optimizer_id, references(:carbs_optimizers, on_delete: :delete_all), null: false
      add :observation_number, :integer, null: false  # Sequential observation number
      add :output, :float, null: false  # The metric value
      add :cost, :float, default: 1.0
      add :is_failure, :boolean, default: false
      add :suggestion_id, :string  # Link to the suggestion that generated this observation

      timestamps()
    end

    create index(:carbs_observations, [:optimizer_id])
    create unique_index(:carbs_observations, [:optimizer_id, :observation_number])

    # Observation parameter values - normalized entity type
    create table(:carbs_observation_params) do
      add :observation_id, references(:carbs_observations, on_delete: :delete_all), null: false
      add :param_name, :string, null: false
      add :param_value, :float, null: false

      timestamps()
    end

    create index(:carbs_observation_params, [:observation_id])
    create unique_index(:carbs_observation_params, [:observation_id, :param_name])

    # Outstanding suggestions table - normalized entity type
    create table(:carbs_suggestions) do
      add :optimizer_id, references(:carbs_optimizers, on_delete: :delete_all), null: false
      add :suggestion_id, :string, null: false
      add :is_remembered, :boolean, default: true
      add :is_observed, :boolean, default: false

      timestamps()
    end

    create index(:carbs_suggestions, [:optimizer_id])
    create unique_index(:carbs_suggestions, [:optimizer_id, :suggestion_id])

    # Suggestion parameter values - normalized entity type
    create table(:carbs_suggestion_params) do
      add :suggestion_id, references(:carbs_suggestions, on_delete: :delete_all), null: false
      add :param_name, :string, null: false
      add :param_value, :float, null: false

      timestamps()
    end

    create index(:carbs_suggestion_params, [:suggestion_id])
    create unique_index(:carbs_suggestion_params, [:suggestion_id, :param_name])
  end
end
