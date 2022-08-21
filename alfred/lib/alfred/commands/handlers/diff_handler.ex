defmodule Alfred.Commands.Handlers.DiffHandler do
  @moduledoc """
  Show diffs from current git working project
  """

  alias Phoenix.PubSub
  alias Alfred.Workers.Git

  @show_time :timer.seconds(5)
  @overlay_topic AlfredWeb.OverlayLive.topic_name()

  def execute do
    diffs = Git.get_diffs()
    PubSub.broadcast(Alfred.PubSub, @overlay_topic, {:new_project_diffs, diffs})

    Task.async(fn ->
      Process.sleep(@show_time)

      PubSub.broadcast(Alfred.PubSub, @overlay_topic, {:new_project_diffs, []})
    end)

    {:ok, :noreply}
  end
end
