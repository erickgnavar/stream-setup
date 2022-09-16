defmodule AlfredWeb.TwitchController do
  @moduledoc """
  Twitch controller to receive pubsub events
  """

  use AlfredWeb, :controller

  @twitch_header_name "twitch-eventsub-message-type"

  @spec webhook(Plug.Conn.t(), map) :: Plug.Conn.t()
  def webhook(conn, params) do
    with [message_type] <- get_req_header(conn, @twitch_header_name),
         {:ok, response} <- handle_event(message_type, params) do
      text(conn, response)
    else
      [] ->
        conn
        |> put_status(400)
        |> text("")

      {:error, reason} when is_binary(reason) ->
        conn
        |> put_status(400)
        |> text(reason)
    end
  end

  @spec handle_event(String.t(), map) :: {:ok, String.t()} | {:error, String.t()}
  defp handle_event("webhook_callback_verification", params) do
    # Used when a new subscription is created and it has to be verified
    {:ok, Map.get(params, "challenge")}
  end

  defp handle_event("notification", params) do
    # handle all regular notifications
    params
    |> get_in(["subscription", "type"])
    |> handle_type(params["event"])
  end

  defp handle_event(_event, _params), do: {:error, "Event not found"}

  defp handle_type("channel.follow", %{"user_name" => _username}) do
    # TODO: show overlay notification
    # TODO: say hi in chat
    {:ok, ""}
  end

  defp handle_type("channel.channel_points_custom_reward_redemption.add", %{
         "user_name" => username,
         "user_input" => raw_message,
         "reward" => %{
           "title" => reward_name
         }
       }) do
    case reward_name do
      "voice" ->
        Alfred.Workers.Voice.queue_message("#{username} dice #{raw_message}")

      "light theme" ->
        Phoenix.PubSub.broadcast(
          Alfred.PubSub,
          AlfredWeb.EmacsChannel.pubsub_topic(),
          {:send_event, "light-theme", %{user: username}}
        )

      _ ->
        nil
    end

    {:ok, ""}
  end

  defp handle_type(_type, _event), do: {:error, "invalid type"}
end
