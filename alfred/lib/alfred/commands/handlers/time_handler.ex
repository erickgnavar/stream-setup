defmodule Alfred.Commands.Handlers.TimeHandler do
  @moduledoc """
  Dummy module that just show current time
  """

  def execute(_sender, _args) do
    {:ok, to_string(DateTime.utc_now())}
  end
end
