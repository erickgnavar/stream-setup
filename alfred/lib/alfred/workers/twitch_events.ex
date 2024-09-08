defmodule Alfred.Workers.TwitchEvents do
  alias Alfred.Core

  use WebSockex

  def start_link(opts) do
    WebSockex.start_link(opts[:uri], __MODULE__, %{})
  end

  def handle_frame({:text, text}, state) do
    message = Jason.decode!(text)
    message_type = get_in(message, ["metadata", "message_type"])
    payload = Map.get(message, "payload")

    handle_message(message_type, payload)

    {:ok, state}
  end

  def handle_message("session_welcome", %{"session" => %{"id" => session_id}}) do
    subscribe_to_events(session_id)
  end

  def handle_message("notification", payload) do
    AlfredWeb.TwitchController.handle_event("notification", payload)
  end

  def handle_message(_message_type, _subscription_type, _payload) do
  end

  @events [
    {"channel.follow", 2},
    # subscription
    {"channel.subscribe", 1},
    {"channel.subscription.gift", 1},
    # redeem channel points
    {"channel.channel_points_custom_reward_redemption.add", 1},
    # raid
    {"channel.raid", 1},
    # predictions
    {"channel.prediction.begin", 1},
    {"channel.prediction.progress", 1},
    {"channel.prediction.lock", 1},
    {"channel.prediction.end", 1},
    # polls
    {"channel.poll.begin", 1},
    {"channel.poll.progress", 1},
    {"channel.poll.end", 1}
  ]

  defp subscribe_to_events(session_id) do
    twitch_user_id = Core.get_config_value!("twitch.user_id")

    Enum.each(@events, fn {event_name, event_version} ->
      payload = %{
        "transport" => %{
          "session_id" => session_id,
          "method" => "websocket"
        },
        "condition" => %{
          "broadcaster_user_id" => twitch_user_id
        },
        "version" => event_version,
        "type" => event_name
      }

      client_id = System.get_env("TWITCH_CLIENT_ID")
      oauth_token = Core.get_config_value!("secret.twitch.access_token")

      headers = [
        {"content-type", "application/json"},
        {"client-id", client_id},
        {"authorization", "Bearer #{oauth_token}"}
      ]

      {:ok, _response} =
        Req.post("https://api.twitch.tv/helix/eventsub/subscriptions",
          headers: headers,
          body: Jason.encode!(payload)
        )
    end)
  end
end
