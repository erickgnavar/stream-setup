defmodule Alfred.Commands.Handlers.VoiceHandler do
  @moduledoc """
  Convert received message to voice using `say` command
  """

  alias Alfred.Workers.Voice

  def execute(_sender, args) do
    args
    |> Enum.join(" ")
    |> Voice.queue_message()

    {:ok, :noreply}
  end
end
