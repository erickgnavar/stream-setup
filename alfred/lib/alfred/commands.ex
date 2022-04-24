defmodule Alfred.Commands do
  @moduledoc """
  The Commands context.
  """

  import Ecto.Query, warn: false
  alias Alfred.Repo

  alias Alfred.Commands.Command

  @doc """
  Returns the list of commands.

  ## Examples

      iex> list_commands()
      [%Command{}, ...]

  """
  def list_commands do
    Repo.all(Command)
  end

  @doc """
  Gets a single command.

  Raises `Ecto.NoResultsError` if the Command does not exist.

  ## Examples

      iex> get_command!(123)
      %Command{}

      iex> get_command!(456)
      ** (Ecto.NoResultsError)

  """
  def get_command!(id), do: Repo.get!(Command, id)

  def get_command_by_trigger(trigger) do
    Command
    |> where(trigger: ^trigger)
    |> Repo.one()
  end

  @doc """
  Creates a command.

  ## Examples

      iex> create_command(%{field: value})
      {:ok, %Command{}}

      iex> create_command(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_command(attrs \\ %{}) do
    %Command{}
    |> Command.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a command.

  ## Examples

      iex> update_command(command, %{field: new_value})
      {:ok, %Command{}}

      iex> update_command(command, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_command(%Command{} = command, attrs) do
    command
    |> Command.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a command.

  ## Examples

      iex> delete_command(command)
      {:ok, %Command{}}

      iex> delete_command(command)
      {:error, %Ecto.Changeset{}}

  """
  def delete_command(%Command{} = command) do
    Repo.delete(command)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking command changes.

  ## Examples

      iex> change_command(command)
      %Ecto.Changeset{data: %Command{}}

  """
  def change_command(%Command{} = command, attrs \\ %{}) do
    Command.changeset(command, attrs)
  end

  @doc """
  Check if there is a command for the given trigger and execute it
  """
  @spec execute(String.t()) :: {:ok, atom | String.t()} | {:error, String.t()}
  def execute(trigger) do
    trigger
    |> get_command_by_trigger()
    |> handle_command()
  end

  defp handle_command(nil) do
    {:error, "Command not found"}
  end

  defp handle_command(%{type: :text, result: result}) do
    {:ok, result}
  end

  defp handle_command(%{type: :code, result: _result}) do
    {:ok, :noreply}
  end
end
