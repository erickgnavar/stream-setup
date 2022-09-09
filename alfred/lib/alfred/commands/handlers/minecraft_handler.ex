defmodule Alfred.Commands.Handlers.MinecraftHandler do
  @moduledoc """
  Setup minecraft mode in emacs
  """

  @topic AlfredWeb.EmacsChannel.pubsub_topic()

  def execute(_sender, _args) do
    Phoenix.PubSub.broadcast(Alfred.PubSub, @topic, {:send_event, "minecraft", %{}})

    {:ok, :noreply}
  end
end
