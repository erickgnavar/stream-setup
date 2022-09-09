defmodule Alfred.Commands.Handlers.LightThemeHandler do
  @moduledoc """
  Send message to emacs to enable light theme
  """

  def execute(sender, _args) do
    Phoenix.PubSub.broadcast(
      Alfred.PubSub,
      AlfredWeb.EmacsChannel.pubsub_topic(),
      {:send_event, "light-theme", %{user: sender}}
    )

    {:ok, :noreply}
  end
end
