defmodule Alfred.Commands.Handlers.LineHandler do
  @moduledoc """
  Highlight received line number in emacs editor
  """

  def execute(sender, [start | rest]) do
    start =
      start
      |> Integer.parse()
      |> case do
        {value, _} -> value
        _ -> nil
      end

    text =
      rest
      |> Enum.join(" ")
      |> case do
        "" -> ""
        comment -> "#{sender}: #{comment}"
      end

    unless is_nil(start) do
      Phoenix.PubSub.broadcast(
        Alfred.PubSub,
        AlfredWeb.EmacsChannel.pubsub_topic(),
        {:send_event, "line", %{start: start, text: text}}
      )
    end

    {:ok, :noreply}
  end

  def execute(_sender, _args), do: {:ok, :noreply}
end
