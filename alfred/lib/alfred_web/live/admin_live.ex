defmodule AlfredWeb.AdminLive do
  use AlfredWeb, :live_view

  alias Phoenix.PubSub
  alias Alfred.Core

  @click_timer :timer.minutes(20)

  @impl true
  def mount(_params, _session, socket) do
    flags = Enum.filter(Core.list_config_params(), &String.starts_with?(&1.key, "flags."))

    # listen to flags updates
    PubSub.subscribe(Alfred.PubSub, Core.flags_topic())

    # start a loop to get a new Spotify access token every @click_timer
    Process.send_after(self(), :click_spotify_login, @click_timer)

    {:ok, assign(socket, :flags, flags)}
  end

  @impl true
  def handle_event("toggle-flag", %{"key" => "flags." <> name}, socket) do
    Core.toggle_flag(name)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:flag_updated, key, value}, socket) do
    flags =
      Enum.map(
        socket.assigns.flags,
        &if(&1.key == key, do: Map.put(&1, :value, value), else: &1)
      )

    {:noreply, assign(socket, :flags, flags)}
  end

  def handle_info(:click_spotify_login, socket) do
    Process.send_after(self(), :click_spotify_login, @click_timer)

    # we need to tell Spotify worker to reload credentials after the click was made in frontend
    Task.async(fn ->
      Process.sleep(:timer.seconds(10))
      Alfred.Workers.Spotify.load_credentials()
    end)

    {:noreply, push_event(socket, "js-exec", %{selector: "#btn-login-spotify"})}
  end
end
