defmodule AlfredWeb.OverlayController do
  use AlfredWeb, :controller

  alias Alfred.Core
  alias Phoenix.PubSub

  @overlay_topic AlfredWeb.OverlayLive.topic_name()
  @command_exit_events %{
    "exit_non_zero" => "error_image",
    "exit_zero" => "success_image"
  }
  @command_exit_keys Map.keys(@command_exit_events)

  def trigger_event(conn, %{"event" => event_name}) do
    with :ok <- handle_event_name(event_name) do
      text(conn, "ok")
    else
      {:error, reason} ->
        conn
        |> put_status(400)
        |> text(reason)
    end
  end

  def handle_event_name(event_name) when event_name in @command_exit_keys do
    @command_exit_events
    |> Map.get(event_name)
    |> Core.get_config_param()
    |> case do
      %{value: url} ->
        PubSub.broadcast(Alfred.PubSub, @overlay_topic, {:change_image, url})

      nil ->
        {:error, "no image"}
    end
  end

  def handle_event_name(_event_name) do
    {:error, "unknown event"}
  end
end
