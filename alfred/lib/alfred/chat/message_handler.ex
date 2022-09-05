defmodule Alfred.Chat.MessageHandler do
  @moduledoc """
  Handler used to listen to client process messages
  when the client process receive a :logged_in message
  now we can join into a channel

  Also will handle all the command messages
  """
  use GenServer

  alias Alfred.Commands

  def start_link({client, channel}) do
    GenServer.start_link(__MODULE__, {client, channel}, name: __MODULE__)
  end

  @impl true
  def init({client, _channel} = state) do
    ExIRC.Client.add_handler(client, self())

    {:ok, state}
  end

  @doc """
  Post a message into channel chat
  """
  @spec post_message(String.t()) :: any
  def post_message(message) do
    GenServer.cast(__MODULE__, {:post_message, message})
  end

  @impl true
  def handle_cast({:post_message, message}, {client, channel} = state) do
    :ok = ExIRC.Client.msg(client, :privmsg, channel, message)
    {:noreply, state}
  end

  @impl true
  def handle_info(:logged_in, {client, channel} = state) do
    :ok = ExIRC.Client.join(client, channel)
    username = Application.get_env(:alfred, :twitch_irc)[:username]

    message = "#{username} connected and ready!"

    ExIRC.Client.msg(client, :privmsg, channel, message)

    {:noreply, state}
  end

  def handle_info({:received, "!" <> command, _sender, channel}, {client, channel} = state) do
    case Commands.execute(command) do
      {:ok, :noreply} ->
        nil

      {:ok, result} when is_binary(result) ->
        :ok = ExIRC.Client.msg(client, :privmsg, channel, result)

      {:error, reason} ->
        :ok = ExIRC.Client.msg(client, :privmsg, channel, reason)
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(_message, state) do
    {:noreply, state}
  end
end
