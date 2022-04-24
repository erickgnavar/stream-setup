defmodule Alfred.CommandsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Alfred.Commands` context.
  """

  @doc """
  Generate a command.
  """
  def command_fixture(attrs \\ %{}) do
    {:ok, command} =
      attrs
      |> Enum.into(%{
        result: "some result",
        trigger: "some trigger",
        type: :text
      })
      |> Alfred.Commands.create_command()

    command
  end
end
