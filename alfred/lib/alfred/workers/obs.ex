defmodule Alfred.Workers.OBS do
  use Fresh

  defp send_message(type, data, opts) do
    payload = %{
      "op" => 6,
      "d" => %{
        "requestId" => Ecto.UUID.generate(),
        "requestType" => type,
        "requestData" => data
      }
    }

    case Keyword.get(opts, :timer, nil) do
      nil -> send(:obs_websocket_client, {:send, Jason.encode!(payload)})
      timer -> Process.send_after(:obs_websocket_client, {:send, Jason.encode!(payload)}, timer)
    end
  end

  @spec toggle_source_filter(String.t(), String.t(), boolean, Keyword.t()) :: tuple
  def toggle_source_filter(filter_name, source_name, new_state, opts \\ [])

  def toggle_source_filter(filter_name, source_name, new_state, opts) do
    send_message(
      "SetSourceFilterEnabled",
      %{
        "filterName" => filter_name,
        "filterEnabled" => new_state,
        "sourceName" => source_name
      },
      opts
    )
  end

  def handle_connect(_status, _headers, state) do
    payload = %{"op" => 1, "d" => %{rpcVersion: 1}}
    {:reply, {:text, Jason.encode!(payload)}, state}
  end

  def handle_info({:send, message}, state) do
    {:reply, [{:text, message}], state}
  end
end
