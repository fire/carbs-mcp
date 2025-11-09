defmodule CarbsMCP.OptimizerParam do
  @moduledoc """
  Ecto schema for storing CARBS optimizer parameters.
  Normalized according to ETNF principles.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "carbs_optimizer_params" do
    belongs_to :optimizer, CarbsMCP.Optimizer
    field :name, :string
    field :space_type, :string
    field :space_min, :float
    field :space_max, :float
    field :space_scale, :float
    field :space_is_integer, :boolean
    field :space_rounding_factor, :integer
    field :search_center, :float
    field :position, :integer
    timestamps()
  end

  @doc false
  def changeset(optimizer_param, attrs) do
    optimizer_param
    |> cast(attrs, [
      :optimizer_id, :name, :space_type, :space_min, :space_max, 
      :space_scale, :space_is_integer, :space_rounding_factor,
      :search_center, :position
    ])
    |> validate_required([:optimizer_id, :name, :space_type, :search_center, :position])
    |> validate_inclusion(:space_type, ["LinearSpace", "LogSpace", "LogitSpace"])
  end
end

