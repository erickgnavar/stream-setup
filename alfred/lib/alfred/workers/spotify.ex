defmodule Alfred.Workers.Spotify do
  @moduledoc """
  Get current song from Spotify
  """
  use Alfred.Workers.FlagGenServer, flag: "flags.spotify"

  alias Alfred.Core
  alias Phoenix.PubSub
  require Logger

  @overlay_topic AlfredWeb.OverlayLive.topic_name()
  @update_interval :timer.seconds(3)

  def post_init(state) do
    Process.send_after(self(), :fetch_current_song, @update_interval)
    # TODO: add auto refresh token loop

    Map.merge(state, %{playing_song: nil})
  end

  @spec fetch_current_song :: {:ok, map} | {:error, String.t() | atom}
  def fetch_current_song do
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
           artist: %{
             name: get_in(payload, ["item", "artists"]) |> List.first() |> Map.get("name")
           },
           playlist_url:
             if get_in(payload, ["context", "type"]) == "playlist" do
               get_in(payload, ["context", "external_urls", "spotify"])
             else
               nil
             end,
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

  def get_playlist do
    __MODULE__
    |> GenServer.call(:get_current_song)
    |> case do
      nil -> nil
      %{playlist_url: playlist_url} -> playlist_url
    end
  end

  @impl true
  def handle_call(:get_current_song, _from, state) do
    {:reply, state.playing_song, state}
  end

  @impl true
  def handle_info(:fetch_current_song, state) do
    current_song =
      with true <- state.flag,
           {:ok, song} <- fetch_current_song() do
        song
      else
        false -> nil
        {:error, _error} -> nil
      end

    Process.send_after(self(), :fetch_current_song, @update_interval)

    # notify overlay process
    PubSub.broadcast(Alfred.PubSub, @overlay_topic, {:playing_song, current_song})

    {:noreply, Map.put(state, :playing_song, current_song)}
  end
end
