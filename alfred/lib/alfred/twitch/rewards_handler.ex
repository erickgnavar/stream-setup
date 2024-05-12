defmodule Alfred.Twitch.RewardsHandler do
  @moduledoc """
  Twitch reward handler, execute some functionality depending reward name
  """

  alias Alfred.Workers.OBS

  @doc """
  For a given reward name execute its related code
  """
  @spec handle(String.t(), String.t(), String.t()) :: any
  def handle("voice", username, text) do
    case Alfred.Core.get_config_param("rewards.voice") do
      nil ->
        nil

      %{value: url} ->
        Phoenix.PubSub.broadcast(
          Alfred.PubSub,
          AlfredWeb.OverlayLive.topic_name(),
          {:new_notification, %{title: "**#{username}** dice", image_url: url}}
        )
    end

    Alfred.Workers.Voice.queue_message("#{username} dice #{text}")
  end

  def handle("light theme", username, _text) do
    Phoenix.PubSub.broadcast(
      Alfred.PubSub,
      AlfredWeb.EmacsChannel.pubsub_topic(),
      {:send_event, "light-theme", %{user: username}}
    )

    mp3 = Alfred.Core.get_config_param("rewards.light_theme_mp3")
    gif = Alfred.Core.get_config_param("rewards.light_theme_gif")

    if mp3 && gif do
      Phoenix.PubSub.broadcast(
        Alfred.PubSub,
        AlfredWeb.OverlayLive.topic_name(),
        {:new_notification,
         %{
           title: "**#{username}** canjeó **light theme**",
           image_url: gif.value,
           sound: mp3.value
         }}
      )
    end
  end

  def handle("burn code", _username, _text) do
    Phoenix.PubSub.broadcast(
      Alfred.PubSub,
      AlfredWeb.EmacsChannel.pubsub_topic(),
      {:send_event, "burn", %{}}
    )
  end

  def handle("wazap", _username, _text) do
    mp3 = Alfred.Core.get_config_param("rewards.wazap_mp3")
    gif = Alfred.Core.get_config_param("rewards.wazap_gif")

    if mp3 && gif do
      Phoenix.PubSub.broadcast(
        Alfred.PubSub,
        AlfredWeb.OverlayLive.topic_name(),
        {:new_notification,
         %{title: "Wazaaaaaaaaaaaaaap", image_url: gif.value, sound: mp3.value}}
      )
    end
  end

  # these are valid games already loaded in emacs
  @valid_emacs_games ["snake", "tetris", "bubbles"]

  def handle("game", username, _text) do
    game = Enum.random(@valid_emacs_games)

    Phoenix.PubSub.broadcast(
      Alfred.PubSub,
      AlfredWeb.EmacsChannel.pubsub_topic(),
      {:send_event, "game", %{"game" => game}}
    )

    mp3 = Alfred.Core.get_config_param("rewards.game_mp3")
    gif = Alfred.Core.get_config_param("rewards.game_gif")

    if mp3 && gif do
      Phoenix.PubSub.broadcast(
        Alfred.PubSub,
        AlfredWeb.OverlayLive.topic_name(),
        {:new_notification,
         %{title: "**#{username}** canjeó **#{game}**", image_url: gif.value, sound: mp3.value}}
      )
    end
  end

  def handle("effect " <> effect_name, username, _text) do
    Phoenix.PubSub.broadcast(
      Alfred.PubSub,
      AlfredWeb.OverlayLive.topic_name(),
      {:new_notification,
       %{
         title: "**#{username}** canjeó **#{String.capitalize(effect_name)} effect**",
         image_url: nil,
         sound: nil
       }}
    )

    Alfred.Workers.OBS.toggle_source_filter(effect_name, "Output Source", true)

    Alfred.Workers.OBS.toggle_source_filter(effect_name, "Output Source", false,
      timer: :timer.seconds(5)
    )
  end

  def handle(reward_name, _username, _text),
    do: {:error, "no handler found for #{reward_name}"}
end
