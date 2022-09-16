defmodule Alfred.Twitch.RewardsHandler do
  @moduledoc """
  Twitch reward handler, execute some functionality depending reward name
  """

  @doc """
  For a given reward name execute its related code
  """
  @spec handle(String.t(), String.t(), String.t()) :: any
  def handle("voice", username, text) do
    Alfred.Workers.Voice.queue_message("#{username} dice #{text}")
  end

  def handle("light theme", username, _text) do
    Phoenix.PubSub.broadcast(
      Alfred.PubSub,
      AlfredWeb.EmacsChannel.pubsub_topic(),
      {:send_event, "light-theme", %{user: username}}
    )
  end

  def handle("burn code", _username, _text) do
    Phoenix.PubSub.broadcast(
      Alfred.PubSub,
      AlfredWeb.EmacsChannel.pubsub_topic(),
      {:send_event, "burn", %{}}
    )
  end

  def handle(reward_name, _username, _text),
    do: {:error, "no handler found for #{reward_name}"}
end
