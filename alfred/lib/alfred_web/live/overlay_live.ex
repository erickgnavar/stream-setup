defmodule AlfredWeb.OverlayLive do
  use AlfredWeb, :live_view

  @topic "overlay"
  @image_showing_time :timer.seconds(3)
  @notification_timer :timer.seconds(5)

  alias Phoenix.PubSub

  def mount(_params, _session, socket) do
    # in this subscription we're going to receive a notification to show image
    PubSub.subscribe(Alfred.PubSub, @topic)

    {:ok,
     socket
     |> assign(:project_diffs, [])
     |> assign(:playing_song, nil)
     |> assign(:last_follow, nil)
     |> assign(:notification, nil)
     |> assign(:image_url, nil)}
  end

  @spec topic_name :: String.t()
  def topic_name, do: @topic

  @doc """
  Return overlay topic name, all updates should be send to this topic
  """
  @spec topic_name :: String.t()
  def topic_name, do: @topic

  def handle_info(:hide_image, socket) do
    {:noreply, assign(socket, :image_url, nil)}
  end

  def handle_info({:change_image, image_url}, socket) do
    Process.send_after(self(), :hide_image, @image_showing_time)
    {:noreply, assign(socket, :image_url, image_url)}
  end

  def handle_info({:new_notification, notification}, socket) do
    Process.send_after(self(), :hide_notification, @notification_timer)
    {:noreply, assign(socket, :notification, notification)}
  end

  def handle_info(:hide_notification, socket) do
    {:noreply, assign(socket, :notification, nil)}
  end

  def handle_info({:new_project_diffs, diffs}, socket) do
    {:noreply, assign(socket, :project_diffs, diffs)}
  end

  def handle_info({:playing_song, song}, socket) do
    {:noreply, assign(socket, :playing_song, song)}
  end

  def handle_info({:last_follow, follow}, socket) do
    {:noreply, assign(socket, :last_follow, follow)}
  end
end
