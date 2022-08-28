defmodule AlfredWeb.CommandControllerTest do
  use AlfredWeb.ConnCase

  import Alfred.CommandsFixtures

  @create_attrs %{result: "some result", trigger: "some trigger", type: "text"}
  @update_attrs %{
    result: "some updated result",
    trigger: "some updated trigger",
    type: "text"
  }
  @invalid_attrs %{result: nil, trigger: nil, type: nil}

  setup :auth

  describe "index" do
    test "lists all commands", %{conn: conn} do
      conn = get(conn, Routes.command_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Commands"
    end
  end

  describe "new command" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.command_path(conn, :new))
      assert html_response(conn, 200) =~ "New Command"
    end
  end

  describe "create command" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.command_path(conn, :create), command: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.command_path(conn, :show, id)

      conn = get(conn, Routes.command_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Command"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.command_path(conn, :create), command: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Command"
    end
  end

  describe "edit command" do
    setup [:create_command]

    test "renders form for editing chosen command", %{conn: conn, command: command} do
      conn = get(conn, Routes.command_path(conn, :edit, command))
      assert html_response(conn, 200) =~ "Edit Command"
    end
  end

  describe "update command" do
    setup [:create_command]

    test "redirects when data is valid", %{conn: conn, command: command} do
      conn = put(conn, Routes.command_path(conn, :update, command), command: @update_attrs)
      assert redirected_to(conn) == Routes.command_path(conn, :show, command)

      conn = get(conn, Routes.command_path(conn, :show, command))
      assert html_response(conn, 200) =~ "some updated result"
    end

    test "renders errors when data is invalid", %{conn: conn, command: command} do
      conn = put(conn, Routes.command_path(conn, :update, command), command: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Command"
    end
  end

  describe "delete command" do
    setup [:create_command]

    test "deletes chosen command", %{conn: conn, command: command} do
      conn = delete(conn, Routes.command_path(conn, :delete, command))
      assert redirected_to(conn) == Routes.command_path(conn, :index)

      assert_error_sent(404, fn ->
        get(conn, Routes.command_path(conn, :show, command))
      end)
    end
  end

  defp create_command(_) do
    command = command_fixture()
    %{command: command}
  end
end
