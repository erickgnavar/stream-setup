defmodule Alfred.Commands.Handlers.PlaylistHandler do
  @moduledoc """
  Show Spotify widget for a period of time and then hide it
  """

  alias Alfred.Workers.Spotify

  def execute do
    case Spotify.get_playlist() do
      nil -> {:ok, :noreply}
      url -> {:ok, url}
    end
  end
end
