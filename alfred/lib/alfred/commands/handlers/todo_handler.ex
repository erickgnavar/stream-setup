defmodule Alfred.Commands.Handlers.TodoHandler do
  @moduledoc """
  Show TODO list on overlay
  """
  alias Phoenix.PubSub
  alias Alfred.{Core, OrgParser}

  @overlay_topic AlfredWeb.OverlayLive.topic_name()
  @show_time :timer.seconds(5)

  def execute(_sender, _args) do
    case Core.get_config_param("todo_path") do
      nil ->
        nil

      %{value: path} ->
        todos = OrgParser.parse(path)

        PubSub.broadcast(Alfred.PubSub, @overlay_topic, {:update_todos, todos})

        Task.async(fn ->
          Process.sleep(@show_time)

          PubSub.broadcast(Alfred.PubSub, @overlay_topic, {:update_todos, nil})
        end)
    end

    {:ok, :noreply}
  end
end
