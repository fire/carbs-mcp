defmodule CarbsMCP.ObservationParam do
  @moduledoc """
  Ecto schema for storing observation parameter values.
  Normalized according to ETNF principles.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "carbs_observation_params" do
    belongs_to :observation, CarbsMCP.Observation
    field :param_name, :string
    field :param_value, :float

    timestamps()
  end

  @doc false
  def changeset(observation_param, attrs) do
    observation_param
    |> cast(attrs, [:observation_id, :param_name, :param_value])
    |> validate_required([:observation_id, :param_name, :param_value])
    |> unique_constraint([:observation_id, :param_name])
  end
end
