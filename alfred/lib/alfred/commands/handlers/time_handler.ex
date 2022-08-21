defmodule Alfred.Commands.Handlers.TimeHandler do
  @moduledoc """
  Dummy module that just show current time
  """

  def execute do
    {:ok, to_string(DateTime.utc_now())}
  end
end
