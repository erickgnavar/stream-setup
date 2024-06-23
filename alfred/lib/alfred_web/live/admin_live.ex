defmodule AlfredWeb.AdminLive do
  use AlfredWeb, :live_view

  alias Phoenix.PubSub
  alias Alfred.Core

  @impl true
  def mount(_params, _session, socket) do
    flags = Enum.filter(Core.list_config_params(), &String.starts_with?(&1.key, "flags."))

    # listen to flags updates
    PubSub.subscribe(Alfred.PubSub, Core.flags_topic())

    {:ok, assign(socket, flags: flags, page_title: "Admin console")}
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
end
