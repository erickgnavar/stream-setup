defmodule Alfred.Commands.Command do
  use Ecto.Schema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime]
  @types [:text, :code]

  schema "commands" do
    field :result, :string
    field :trigger, :string

    field :type, Ecto.Enum, values: @types, default: :text

    timestamps()
  end

  @doc false
  def changeset(command, attrs) do
    command
    |> cast(attrs, [:trigger, :type, :result])
    |> validate_required([:trigger, :type, :result])
  end
end
