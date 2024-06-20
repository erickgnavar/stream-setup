defmodule Alfred.Commands.Handlers.SongHandler do
  @moduledoc """
  Show Spotify widget in overlay for a period of time and then hide it
  """

  alias Phoenix.PubSub
  alias Alfred.Workers.Spotify

  @show_time :timer.seconds(8)
  @overlay_topic AlfredWeb.OverlayLive.topic_name()

  def execute(_sender, _args) do
    case Spotify.get_current_song() do
      nil ->
        {:ok, :noreply}

      current_song ->
        PubSub.broadcast(Alfred.PubSub, @overlay_topic, {:playing_song, current_song})

        Task.async(fn ->
          Process.sleep(@show_time)

          PubSub.broadcast(Alfred.PubSub, @overlay_topic, {:playing_song, nil})
        end)

        {:ok, "🎵 #{current_song.name} - #{current_song.artist.name} 🎵"}
    end
  end
end
