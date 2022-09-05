defmodule Alfred.Commands.Handlers.PlaylistHandler do
  @moduledoc """
  Show Spotify widget for a period of time and then hide it
  """

  alias Alfred.Workers.Spotify

  def execute(_sender, _args) do
    case Spotify.get_current_song() do
      %{playlist_url: url} when is_binary(url) -> {:ok, url}
      _ -> {:ok, :noreply}
    end
  end
end
