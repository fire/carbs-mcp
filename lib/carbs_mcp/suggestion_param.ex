defmodule CarbsMCP.SuggestionParam do
  @moduledoc """
  Ecto schema for storing suggestion parameter values.
  Normalized according to ETNF principles.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "carbs_suggestion_params" do
    belongs_to :suggestion, CarbsMCP.Suggestion
    field :param_name, :string
    field :param_value, :float

    timestamps()
  end

  @doc false
  def changeset(suggestion_param, attrs) do
    suggestion_param
    |> cast(attrs, [:suggestion_id, :param_name, :param_value])
    |> validate_required([:suggestion_id, :param_name, :param_value])
    |> unique_constraint([:suggestion_id, :param_name])
  end
end
