defmodule Alfred.Commands.Handlers.HelpHandler do
  @moduledoc """
  Show a list of all commands
  """

  alias Alfred.Commands

  def execute(_sender, _args) do
    text =
      Commands.list_commands()
      |> Enum.map(fn %{trigger: trigger} ->
        "!#{trigger}"
      end)
      |> Enum.join(", ")

    {:ok, text}
  end
end
