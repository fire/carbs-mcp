defmodule CarbsMCP.Suggestion do
  @moduledoc """
  Ecto schema for storing CARBS suggestions.
  Normalized according to ETNF principles.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "carbs_suggestions" do
    belongs_to :optimizer, CarbsMCP.Optimizer
    field :suggestion_id, :string
    field :is_remembered, :boolean
    field :is_observed, :boolean

    has_many :param_values, CarbsMCP.SuggestionParam

    timestamps()
  end

  @doc false
  def changeset(suggestion, attrs) do
    suggestion
    |> cast(attrs, [:optimizer_id, :suggestion_id, :is_remembered, :is_observed])
    |> validate_required([:optimizer_id, :suggestion_id])
    |> unique_constraint([:optimizer_id, :suggestion_id])
  end
end
