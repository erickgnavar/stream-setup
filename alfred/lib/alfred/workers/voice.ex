defmodule Alfred.Workers.Voice do
  @moduledoc """
  Convert text to voice using `say` command
  """
  use Alfred.Workers.FlagGenServer, flag: "flags.voice"

  @update_interval :timer.seconds(1)
  @allowed_chars '0123456789áéíóúüabcdefghijklmnñopqrstuvwxyz '

  def queue_message(message) do
    GenServer.cast(__MODULE__, {:queue_message, clean_message(message)})
  end

  @impl true
  def handle_continue(:setup_state, state) do
    # start a loop to check items in queue
    Process.send_after(self(), :process_item, @update_interval)
    new_state = %{queue: :queue.new()}

    {:noreply, Map.merge(state, new_state)}
  end

  @impl true
  def handle_cast({:queue_message, message}, state) do
    {:noreply, %{state | queue: :queue.cons(message, state.queue)}}
  end

  @impl true
  def handle_info(:process_item, state) do
    queue =
      case :queue.out_r(state.queue) do
        {{:value, message}, queue} ->
          if state.flag do
            run_say_comand(message)
          end

          queue

        {:empty, queue} ->
          queue
      end

    Process.send_after(self(), :process_item, @update_interval)
    {:noreply, %{state | queue: queue}}
  end

  @spec clean_message(String.t()) :: String.t()
  defp clean_message(raw_text) do
    raw_text
    |> String.downcase()
    |> String.to_charlist()
    |> Enum.filter(&(&1 in @allowed_chars))
    |> to_string()
  end

  @spec run_say_comand(String.t()) :: any
  def run_say_comand(text) do
    # Paulina is a Spanish voice already configured in macOS
    System.cmd("say", ["-v", "Paulina", text])
  end
end
