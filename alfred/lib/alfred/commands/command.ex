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
    |> validate_required([:trigger, :type])
    |> setup_required_field()
  end

  defp setup_required_field(%{valid?: true} = changeset) do
    required_fields =
      changeset
      |> get_field(:type)
      |> case do
        :code -> []
        :text -> [:result]
      end

    validate_required(changeset, required_fields)
  end

  defp setup_required_field(changeset), do: changeset
end
