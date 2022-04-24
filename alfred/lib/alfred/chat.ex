defmodule Alfred.Chat do
  @moduledoc """
  Chat supervisor, it will handle all the process related to chat irc connection
  """
  use Supervisor

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, client} = ExIRC.start_link!()

    credentials = Application.get_env(:alfred, :twitch_irc)

    children =
      if credentials do
        [
          {Alfred.Chat.ConnectionHandler, client},
          # initialize login handler to join the given channel as soon as client is connected
          {Alfred.Chat.MessageHandler, {client, Keyword.get(credentials, :channel)}}
        ]
      else
        []
      end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
