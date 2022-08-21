defmodule AlfredWeb.CommandController do
  use AlfredWeb, :controller

  alias Alfred.Commands
  alias Alfred.Commands.Command

  def index(conn, _params) do
    commands = Commands.list_commands()
    render(conn, "index.html", commands: commands)
  end

  def new(conn, _params) do
    changeset = Commands.change_command(%Command{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"command" => command_params}) do
    case Commands.create_command(command_params) do
      {:ok, command} ->
        conn
        |> put_flash(:info, "Command created successfully.")
        |> redirect(to: Routes.command_path(conn, :show, command))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    command = Commands.get_command!(id)
    render(conn, "show.html", command: command)
  end

  def edit(conn, %{"id" => id}) do
    command = Commands.get_command!(id)
    changeset = Commands.change_command(command)
    render(conn, "edit.html", command: command, changeset: changeset)
  end

  def update(conn, %{"id" => id, "command" => command_params}) do
    command = Commands.get_command!(id)

    case Commands.update_command(command, command_params) do
      {:ok, command} ->
        conn
        |> put_flash(:info, "Command updated successfully.")
        |> redirect(to: Routes.command_path(conn, :show, command))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", command: command, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    command = Commands.get_command!(id)
    {:ok, _command} = Commands.delete_command(command)

    conn
    |> put_flash(:info, "Command deleted successfully.")
    |> redirect(to: Routes.command_path(conn, :index))
  end
end
