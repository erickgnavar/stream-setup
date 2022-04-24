defmodule Alfred.CommandsTest do
  use Alfred.DataCase

  alias Alfred.Commands

  describe "commands" do
    alias Alfred.Commands.Command

    import Alfred.CommandsFixtures

    @invalid_attrs %{result: nil, trigger: nil, type: nil}

    test "list_commands/0 returns all commands" do
      command = command_fixture()
      assert Commands.list_commands() == [command]
    end

    test "get_command!/1 returns the command with given id" do
      command = command_fixture()
      assert Commands.get_command!(command.id) == command
    end

    test "create_command/1 with valid data creates a command" do
      valid_attrs = %{result: "some result", trigger: "some trigger", type: :text}

      assert {:ok, %Command{} = command} = Commands.create_command(valid_attrs)
      assert command.result == "some result"
      assert command.trigger == "some trigger"
      assert command.type == :text
    end

    test "create_command/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Commands.create_command(@invalid_attrs)
    end

    test "update_command/2 with valid data updates the command" do
      command = command_fixture()

      update_attrs = %{
        result: "some updated result",
        trigger: "some updated trigger",
        type: :code
      }

      assert {:ok, %Command{} = command} = Commands.update_command(command, update_attrs)
      assert command.result == "some updated result"
      assert command.trigger == "some updated trigger"
      assert command.type == :code
    end

    test "update_command/2 with invalid data returns error changeset" do
      command = command_fixture()
      assert {:error, %Ecto.Changeset{}} = Commands.update_command(command, @invalid_attrs)
      assert command == Commands.get_command!(command.id)
    end

    test "delete_command/1 deletes the command" do
      command = command_fixture()
      assert {:ok, %Command{}} = Commands.delete_command(command)
      assert_raise Ecto.NoResultsError, fn -> Commands.get_command!(command.id) end
    end

    test "change_command/1 returns a command changeset" do
      command = command_fixture()
      assert %Ecto.Changeset{} = Commands.change_command(command)
    end
  end
end
