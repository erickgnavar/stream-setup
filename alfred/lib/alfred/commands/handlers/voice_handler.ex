defmodule Alfred.Commands.Handlers.VoiceHandler do
  @moduledoc """
  Convert received message to voice using `say` command
  """

  alias Alfred.Workers.Voice

  def execute(sender, args) do
    raw_message = Enum.join(args, " ")

    Voice.queue_message("#{sender} dice #{raw_message}")

    {:ok, :noreply}
  end
end
