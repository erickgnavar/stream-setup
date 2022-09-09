defmodule Alfred.Commands.Handlers.VoiceHandler do
  @moduledoc """
  Convert received message to voice using `say` command
  """

  @allowed_chars '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ '

  def execute(_sender, args) do
    text =
      args
      |> Enum.join(" ")
      |> String.to_charlist()
      |> Enum.filter(&(&1 in @allowed_chars))
      |> to_string()

    # Paulina is a Spanish voice already configured in macOS
    System.cmd("say", ["-v", "Paulina", text])

    {:ok, :noreply}
  end
end
