defmodule Alfred.Core.ConfigParam do
  use Ecto.Schema
  import Ecto.Changeset

  schema "config_params" do
    field :key, :string
    field :value, :string

    timestamps()
  end

  @doc false
  def changeset(config_param, attrs) do
    config_param
    |> cast(attrs, [:key, :value])
    |> validate_required([:key, :value])
  end
end
