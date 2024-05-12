defmodule Alfred.Workers.Twitch do
  @moduledoc """
  Get data from Twitch API
  """
  use Alfred.Workers.FlagGenServer, flag: "flags.twitch"

  alias Alfred.Core
  alias Phoenix.PubSub
  require Logger

  @overlay_topic AlfredWeb.OverlayLive.topic_name()
  @update_interval :timer.minutes(1)

  @impl true
  def handle_continue(:setup_state, state) do
    Process.send_after(self(), :notify_last_follow, @update_interval)

    new_state = Map.merge(state, %{credentials: read_credentials()})

    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:refresh_token, state) do
    Logger.info("Refresing Twitch access token")

    with %{value: refresh_token} <- Core.get_config_param("secret.twitch.refresh_token"),
         {:ok, payload} <- refresh_token_request(refresh_token) do
      Core.update_config_param("secret.twitch.access_token", payload["access_token"])
      Core.update_config_param("secret.twitch.refresh_token", payload["refresh_token"])

      new_credentials = %{state.credentials | access_token: payload["access_token"]}

      {:noreply, Map.put(state, :credentials, new_credentials)}
    else
      error ->
        Logger.error("Error when trying to refresh Twitch access token: #{inspect(error)}")

        {:noreply, state}
    end
  end

  def handle_info(:notify_last_follow, state) do
    with true <- state.flag,
         %{access_token: access_token, user_id: user_id} <- state.credentials,
         {:ok, follow} <- get_latest_follow(access_token, user_id) do
      PubSub.broadcast(Alfred.PubSub, @overlay_topic, {:last_follow, follow})
    end

    Process.send_after(self(), :notify_last_follow, @update_interval)
    {:noreply, state}
  end

  @spec refresh_token_request(String.t()) :: {:ok, map} | {:error, String.t()}
  defp refresh_token_request(refresh_token) do
    url = "https://id.twitch.tv/oauth2/token"
    headers = [{"content-type", "application/x-www-form-urlencoded"}]

    payload =
      :ueberauth
      |> Application.get_env(Ueberauth.Strategy.Twitch.OAuth)
      |> Map.new()
      |> Map.take([:client_id, :client_secret])
      |> Map.merge(%{
        grant_type: "refresh_token",
        refresh_token: refresh_token
      })

    case Req.post(url, body: URI.encode_query(payload), headers: headers) do
      {:ok, %{status: 200, body: body}} ->
        body

      error ->
        {:error, error}
    end
  end

  @spec get_latest_follow(String.t(), String.t()) :: {:ok, map} | {:error, String.t() | atom}
  defp get_latest_follow(access_token, user_id) do
    %{client_id: client_id} =
      :ueberauth
      |> Application.get_env(Ueberauth.Strategy.Twitch.OAuth)
      |> Map.new()

    url = "https://api.twitch.tv/helix/channels/followers?broadcaster_id=#{user_id}"

    headers = [
      {"authorization", "Bearer #{access_token}"},
      {"client-id", client_id}
    ]

    case Req.get(url, headers: headers) do
      {:ok, %{status: 200, body: body}} ->
        case body["data"] do
          [] -> {:error, "no follows"}
          [latest | _tail] -> {:ok, latest["user_name"]}
        end

      {:ok, %{status: 401}} ->
        GenServer.cast(__MODULE__, :refresh_token)

        {:error, :expired_token}

      error ->
        Logger.error("Twitch request error: #{inspect(error)}")
        {:error, "unexpected error"}
    end
  end

  @spec read_credentials :: String.t() | nil
  defp read_credentials do
    access_token = Core.get_config_value!("secret.twitch.access_token")
    user_id = Core.get_config_value!("twitch.user_id")

    # these values aren't booleans so we need to use && instead of and
    if access_token && user_id do
      %{user_id: user_id, access_token: access_token}
    else
      %{}
    end
  end
end
