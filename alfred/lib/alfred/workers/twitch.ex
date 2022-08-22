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
    {:noreply, state}
  end

  @spec get_latest_follow :: {:ok, map} | {:error, String.t() | atom}
  def get_latest_follow() do
    %{value: user_id} = Core.get_config_param("twitch.user_id")
    %{value: access_token} = Core.get_config_param("twitch.access_token")

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

  def handle_info(:notify_last_follow, state) do
    {:ok, follow} = get_latest_follow()
    PubSub.broadcast(Alfred.PubSub, @overlay_topic, {:last_follow, follow})
    Process.send_after(self(), :notify_last_follow, @update_interval)
    {:noreply, state}
  end
end
