defmodule Alfred.Commands.Handlers.SongHandler do
  @moduledoc """
  Show Spotify widget in overlay for a period of time and then hide it
  """

  alias Phoenix.PubSub
  alias Alfred.Workers.Spotify

  @show_time :timer.seconds(5)
  @overlay_topic AlfredWeb.OverlayLive.topic_name()

  def execute do
    current_song = Spotify.get_current_song()
    PubSub.broadcast(Alfred.PubSub, @overlay_topic, {:playing_song, current_song})

    Task.async(fn ->
      Process.sleep(@show_time)

      PubSub.broadcast(Alfred.PubSub, @overlay_topic, {:playing_song, nil})
    end)

    {:ok, :noreply}
  end
end
