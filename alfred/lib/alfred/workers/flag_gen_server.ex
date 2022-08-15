defmodule Alfred.Workers.FlagGenServer do
  @moduledoc """
  Macro to configure a genserver that listen to a specific config flag
  """

  defmacro __using__(opts) do
    quote do
      use GenServer
      @flag unquote(Keyword.get(opts, :flag))

      def start_link(_opts) do
        flag =
          case Alfred.Core.get_config_param(@flag) do
            nil -> false
            %{value: value} -> value == "true"
          end

        GenServer.start_link(__MODULE__, %{flag: flag}, name: __MODULE__)
      end

      @impl true
      def init(state) do
        Phoenix.PubSub.subscribe(Alfred.PubSub, Alfred.Core.flags_topic())
        {:ok, post_init(state)}
      end

      @impl true
      def handle_info({:flag_updated, @flag, value}, state) do
        {:noreply, Map.put(state, :flag, value == "true")}
      end

      @impl true
      def handle_info({:flag_updated, _key, _value}, state) do
        # ignore other flags
        {:noreply, state}
      end
    end
  end
end
