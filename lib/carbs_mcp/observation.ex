defmodule CarbsMCP.Observation do
  @moduledoc """
  Ecto schema for storing CARBS observations.
  Normalized according to ETNF principles.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "carbs_observations" do
    belongs_to :optimizer, CarbsMCP.Optimizer
    field :observation_number, :integer
    field :output, :float
    field :cost, :float
    field :is_failure, :boolean
    field :suggestion_id, :string
    
    has_many :param_values, CarbsMCP.ObservationParam
    
    timestamps()
  end

  @doc false
  def changeset(observation, attrs) do
    observation
    |> cast(attrs, [:optimizer_id, :observation_number, :output, :cost, :is_failure, :suggestion_id])
    |> validate_required([:optimizer_id, :observation_number, :output])
    |> unique_constraint([:optimizer_id, :observation_number])
  end
end

