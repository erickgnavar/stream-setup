defmodule AlfredWeb.OverlayLive do
  use AlfredWeb, :live_view

  @topic "overlay"
  @chat_sentiment_analysis_topic "chat_sentiment_analysis_topic"
  @image_showing_time :timer.seconds(3)
  @notification_timer :timer.seconds(5)
  @emoji_positive "😀"
  @emoji_neutral "😐"
  @emoji_negative "🥲"

  alias Phoenix.PubSub

  def mount(_params, _session, socket) do
    # in this subscription we're going to receive a notification to show image
    PubSub.subscribe(Alfred.PubSub, @topic)

    # subscribe to sentiment analysis topic
    PubSub.subscribe(Alfred.PubSub, @chat_sentiment_analysis_topic)

    {:ok,
     socket
     |> assign(:project_diffs, [])
     |> assign(:playing_song, nil)
     |> assign(:playing_song_exit_class, nil)
     |> assign(:last_follow, nil)
     |> assign(:notification, nil)
     |> assign(:notification_hide_class, nil)
     |> assign(:emoji, nil)
     |> assign(:image_url, nil)}
  end

  @doc """
  Return overlay topic name, all updates should be send to this topic
  """
  @spec topic_name :: String.t()
  def topic_name, do: @topic

  @doc """
  Return chat sentiment analysis topic name
  """
  @spec sentiment_analysis_topic_name :: String.t()
  def sentiment_analysis_topic_name, do: @chat_sentiment_analysis_topic

  @doc """
  Render received markdown text to HTML
  """
  @spec render_markdown(String.t()) :: String.t()
  # TODO: check how to remove root p tag
  def render_markdown(text), do: Earmark.as_html!(text, [])

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
    Process.send_after(self(), :clean_notification, :timer.seconds(1))
    {:noreply, assign(socket, notification_hide_class: "hide-notification")}
  end

  def handle_info(:clean_notification, socket) do
    {:noreply, assign(socket, notification: nil, notification_hide_class: nil)}
  end

  def handle_info({:new_project_diffs, diffs}, socket) do
    {:noreply, assign(socket, :project_diffs, diffs)}
  end

  def handle_info({:playing_song, nil}, socket) do
    # animation run in .5 seconds so we can safely run this after 1 second
    Process.send_after(self(), :playing_song_exit, :timer.seconds(1))
    {:noreply, assign(socket, :playing_song_exit_class, "playing-song-container-exit")}
  end

  def handle_info({:playing_song, song}, socket) do
    {:noreply, assign(socket, :playing_song, song)}
  end

  def handle_info(:playing_song_exit, socket) do
    {:noreply, assign(socket, playing_song: nil, playing_song_exit_class: nil)}
  end

  def handle_info({:last_follow, follow}, socket) do
    {:noreply, assign(socket, :last_follow, follow)}
  end

  def handle_info({:new_message, text}, socket) do
    emoji =
      case Nx.Serving.batched_run(Alfred.Serving, text) do
        %{predictions: predictions} ->
          predictions
          |> Enum.sort(&(&1.score > &2.score))
          |> hd()
          |> Map.get(:label)
          |> case do
            "NEU" -> @emoji_neutral
            "POS" -> @emoji_positive
            "NEG" -> @emoji_negative
          end

        _ ->
          nil
      end

    Process.send_after(self(), :hide_emoji, :timer.seconds(3))

    {:noreply, assign(socket, :emoji, emoji)}
  end

  def handle_info(:hide_emoji, socket) do
    {:noreply, assign(socket, :emoji, nil)}
  end
end
