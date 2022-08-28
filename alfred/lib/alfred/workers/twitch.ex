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

  def handle_info(:notify_last_follow, state) do
    with true <- state.flag,
         %{access_token: access_token, user_id: user_id} <- state.credentials,
         {:ok, follow} <- get_latest_follow(access_token, user_id) do
      PubSub.broadcast(Alfred.PubSub, @overlay_topic, {:last_follow, follow})
    end

    Process.send_after(self(), :notify_last_follow, @update_interval)
    {:noreply, state}
  end

  @spec get_latest_follow(String.t(), String.t()) :: {:ok, map} | {:error, String.t() | atom}
  defp get_latest_follow(access_token, user_id) do
    %{client_id: client_id} =
      :ueberauth
      |> Application.get_env(Ueberauth.Strategy.Twitch.OAuth)
      |> Map.new()

    url = "https://api.twitch.tv/helix/users/follows?to_id=#{user_id}"

    headers = [
      {"authorization", "Bearer #{access_token}"},
      {"client-id", client_id}
    ]

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, payload} = Jason.decode(body)

        case payload["data"] do
          [] -> {:error, "no follows"}
          [latest | _tail] -> {:ok, latest["from_name"]}
        end

      error ->
        Logger.error("Twitch request error: #{inspect(error)}")
        {:error, "unexpected error"}
    end
  end

  @spec read_credentials :: String.t() | nil
  defp read_credentials do
    access_token =
      case Core.get_config_param("secret.twitch.access_token") do
        nil -> nil
        %{value: ""} -> nil
        %{value: access_token} -> access_token
      end

    user_id =
      case Core.get_config_param("twitch.user_id") do
        nil -> nil
        %{value: ""} -> nil
        %{value: user_id} -> user_id
      end

    # these values aren't booleans so we need to use && instead of and
    if access_token && user_id do
      %{user_id: user_id, access_token: access_token}
    else
      %{}
    end
  end
end
