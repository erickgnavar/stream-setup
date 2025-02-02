defmodule Alfred.Workers.Spotify do
  @moduledoc """
  Get current song from Spotify
  """
  use Alfred.Workers.FlagGenServer, flag: "flags.spotify"

  alias Alfred.Core
  require Logger

  @update_interval :timer.seconds(3)

  @doc """
  Get current playing song
  """
  @spec get_current_song :: struct | nil
  def get_current_song do
    __MODULE__
    |> GenServer.call(:get_current_song)
    |> case do
      nil -> nil
      song -> song
    end
  end

  @impl true
  def handle_continue(:setup_state, state) do
    Process.send_after(self(), :fetch_current_song, @update_interval)

    new_state =
      Map.merge(state, %{playing_song: nil})

    {:noreply, new_state}
  end

  @impl true
  def handle_call(:get_current_song, _from, state) do
    {:reply, state.playing_song, state}
  end

  @impl true
  def handle_cast(:refresh_token, state) do
    Logger.info("Refreshing Spotify access token")

    with %{value: access_token} <- Core.get_config_param("secret.spotify.access_token"),
         %{value: refresh_token} <- Core.get_config_param("secret.spotify.refresh_token"),
         credentials <- Spotify.Credentials.new(access_token, refresh_token),
         {:ok, %Spotify.Credentials{access_token: new_access_token}} <-
           Spotify.Authentication.refresh(credentials) do
      # persist access token in case process crashes, this way newest token will be read
      # at process startup
      Core.update_config_param("secret.spotify.access_token", new_access_token)

      {:noreply, state}
    else
      error ->
        Logger.error("Error when trying to refresh Spotify access token: #{inspect(error)}")

        {:noreply, state}
    end
  end

  @impl true
  def handle_info(:fetch_current_song, state) do
    current_song =
      with true <- state.flag,
           access_token when not is_nil(access_token) <- get_access_token(),
           {:ok, song} <- fetch_current_song(access_token) do
        song
      else
        false -> nil
        nil -> nil
        {:error, _error} -> nil
      end

    Process.send_after(self(), :fetch_current_song, @update_interval)

    {:noreply, Map.put(state, :playing_song, current_song)}
  end

  defp get_access_token, do: Core.get_config_value!("secret.spotify.access_token")

  @spec fetch_current_song(String.t()) :: {:ok, map} | {:error, String.t() | atom}
  defp fetch_current_song(access_token) do
    url = "https://api.spotify.com/v1/me/player/currently-playing"

    case Req.get(url, headers: [{"authorization", "Bearer #{access_token}"}]) do
      {:ok, %{status: 204}} ->
        {:error, :no_playing}

      {:ok, %{status: 401}} ->
        GenServer.cast(__MODULE__, :refresh_token)

        {:error, :expired_token}

      {:ok, %{status: 200, body: body}} ->
        {:ok,
         %{
           name: get_in(body, ["item", "name"]),
           artist: %{
             name: get_in(body, ["item", "artists"]) |> List.first() |> Map.get("name")
           },
           playlist_url:
             if get_in(body, ["context", "type"]) == "playlist" do
               get_in(body, ["context", "external_urls", "spotify"])
             else
               nil
             end,
           album: %{
             name: get_in(body, ["item", "album", "name"]),
             # take second cover image
             image_url:
               body |> get_in(["item", "album", "images"]) |> Enum.at(1) |> Map.get("url")
           }
         }}

      error ->
        Logger.error("Spotify request error: #{inspect(error)}")
        {:error, "unexpected error"}
    end
  end
end
