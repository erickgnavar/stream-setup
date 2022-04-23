defmodule Alfred.CoreFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Alfred.Core` context.
  """

  @doc """
  Generate a config_param.
  """
  def config_param_fixture(attrs \\ %{}) do
    {:ok, config_param} =
      attrs
      |> Enum.into(%{
        key: "some key",
        value: "some value"
      })
      |> Alfred.Core.create_config_param()

    config_param
  end
end
