defmodule Alfred.Commands.Handlers.ProjectHandler do
  @moduledoc """
  Show and configure current project
  """

  alias Alfred.Core

  def execute(_sender, []) do
    case Core.get_config_param("project") do
      nil -> {:ok, :noreply}
      %{value: value} -> {:ok, value}
    end
  end

  def execute(sender, args) do
    case Core.get_config_param("twitch.admin") do
      nil ->
        {:ok, :noreply}

      %{value: ^sender} ->
        text = Enum.join(args, " ")
        Core.update_config_param("project", text)
        {:ok, "Project updated!"}

      _ ->
        {:ok, :noreply}
    end
  end
end
