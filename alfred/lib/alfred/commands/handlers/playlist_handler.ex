defmodule Alfred.Commands.Handlers.PlaylistHandler do
  @moduledoc """
  Show Spotify widget for a period of time and then hide it
  """

  alias Alfred.Workers.Spotify

  def execute do
    case Spotify.get_current_song() do
      nil -> {:ok, :noreply}
      %{playlist_url: url} -> {:ok, url}
    end
  end
end
