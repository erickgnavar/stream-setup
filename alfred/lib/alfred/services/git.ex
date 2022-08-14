defmodule Alfred.Services.Git do
  @moduledoc """
  Get git project info in real time
  """
  use Alfred.Services.FlagGenServer, flag: "flags.git"

  alias Alfred.Core
  alias Phoenix.PubSub

  @overlay_topic AlfredWeb.OverlayLive.topic_name()
  @update_interval :timer.seconds(1)

  def post_init(state) do
    # in case this is pre configured we use the value from database
    project_dir =
      case Core.get_config_param("git_project_dir") do
        nil -> ""
        %{value: value} -> value
      end

    # start a loop to have diffs list always updated
    Process.send_after(self(), :get_diffs, @update_interval)

    Map.merge(state, %{project_dir: project_dir, diffs: []})
  end

  @doc """
  Change current project dir, all diffs will be calculated using new dir
  """
  @spec change_project_dir(String.t()) :: any
  def change_project_dir(new_project_dir) do
    GenServer.cast(__MODULE__, {:change_project_dir, new_project_dir})
  end

  @impl true
  def handle_info(:get_diffs, %{project_dir: project_dir} = state) do
    diffs =
      if state.flag and File.dir?(Path.join(project_dir, ".git")) do
        File.cd!(project_dir, fn ->
          case System.cmd("git", ["diff", "--numstat"]) do
            {output, 0} ->
              output
              |> String.split("\n")
              |> Enum.reject(&(&1 == ""))
              |> Enum.map(&String.split(&1, "\t"))
              |> Enum.map(fn [add, delete, filename] ->
                %{add: add, delete: delete, filename: filename}
              end)

            _ ->
              []
          end
        end)
      else
        []
      end

    Process.send_after(self(), :get_diffs, @update_interval)

    # only notify if diffs changed
    if diffs != state.diffs do
      PubSub.broadcast(Alfred.PubSub, @overlay_topic, {:new_project_diffs, diffs})
    end

    {:noreply, Map.put(state, :diffs, diffs)}
  end

  @impl true
  def handle_cast({:change_project_dir, new_project_dir}, state) do
    {:noreply, Map.put(state, :project_dir, new_project_dir)}
  end
end
