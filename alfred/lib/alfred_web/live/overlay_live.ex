defmodule AlfredWeb.OverlayLive do
  use AlfredWeb, :live_view

  @topic "overlay"
  @image_showing_time :timer.seconds(3)

  alias Phoenix.PubSub

  def mount(_params, _session, socket) do
    # in this subscription we're going to receive a notification to show image
    PubSub.subscribe(Alfred.PubSub, @topic)

    {:ok,
     socket
     |> assign(:project_diffs, [])
     |> assign(:image_url, nil)}
  end

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

  def handle_info({:new_project_diffs, diffs}, socket) do
    {:noreply, assign(socket, :project_diffs, diffs)}
  end
end
