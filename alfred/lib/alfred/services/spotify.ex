defmodule Alfred.Services.Spotify do
  @moduledoc """
  Get current song from Spotify
  """
  use Alfred.Services.FlagGenServer, flag: "flags.spotify"

  alias Alfred.Core
  alias Phoenix.PubSub
  require Logger

  @overlay_topic AlfredWeb.OverlayLive.topic_name()
  @update_interval :timer.seconds(3)

  def post_init(state) do
    Process.send_after(self(), :get_current_song, @update_interval)
    # TODO: add auto refresh token loop

    state
  end

  @spec get_current_song :: {:ok, map} | {:error, String.t() | atom}
  def get_current_song do
    url = "https://api.spotify.com/v1/me/player/currently-playing"
    %{value: access_token} = Core.get_config_param("spotify.access_token")

    case HTTPoison.get(url, [{"authorization", "Bearer #{access_token}"}]) do
      {:ok, %HTTPoison.Response{status_code: 204}} ->
        {:error, :no_playing}

      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, payload} = Jason.decode(body)

        {:ok,
         %{
           name: get_in(payload, ["item", "name"]),
           album: %{
             name: get_in(payload, ["item", "album", "name"]),
             # take second cover image
             image_url:
               payload |> get_in(["item", "album", "images"]) |> Enum.at(1) |> Map.get("url")
           }
         }}

      error ->
        Logger.error("Spotify request error: #{inspect(error)}")
        {:error, "unexpected error"}
    end
  end

  @impl true
  def handle_info(:get_current_song, state) do
    current_song =
      with true <- state.flag,
           {:ok, song} <- get_current_song() do
        song
      else
        false -> nil
        {:error, _error} -> nil
      end

    Process.send_after(self(), :get_current_song, @update_interval)

    # notify overlay process
    PubSub.broadcast(Alfred.PubSub, @overlay_topic, {:playing_song, current_song})

    {:noreply, state}
  end
end
