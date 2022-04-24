defmodule Alfred.Chat.ConnectionHandler do
  use GenServer

  def start_link(client) do
    %{username: username, password: password} =
      :alfred
      |> Application.get_env(:twitch_irc)
      |> Map.new()

    state = %{
      host: "irc.chat.twitch.tv",
      # it doesn't support ssl so we use non secure port
      port: 6667,
      pass: password,
      nick: username,
      user: username,
      name: username,
      client: client
    }

    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    :ok = ExIRC.Client.add_handler(state.client, self())
    :ok = ExIRC.Client.connect!(state.client, state.host, state.port)
    {:ok, state}
  end

  def handle_info({:connected, _server, _port}, state) do
    :ok = ExIRC.Client.logon(state.client, state.pass, state.nick, state.user, state.name)
    {:noreply, state}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end
end
