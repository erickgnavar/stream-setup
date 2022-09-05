defmodule AlfredWeb.EmacsChannel do
  use AlfredWeb, :channel

  alias Phoenix.PubSub

  @pubsub_topic "emacs"

  def pubsub_topic, do: @pubsub_topic

  @impl true
  def join("emacs:lobby", payload, socket) do
    if authorized?(payload) do
      PubSub.subscribe(Alfred.PubSub, @pubsub_topic)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_info({:send_event, event, payload}, socket) do
    broadcast(socket, event, payload)
    {:noreply, socket}
  end

  # used to keep alive connection
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    # TODO: define some authorization method
    true
  end
end
