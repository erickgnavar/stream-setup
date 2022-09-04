defmodule AlfredWeb.EmacsChannelTest do
  use AlfredWeb.ChannelCase

  setup do
    {:ok, _, socket} =
      AlfredWeb.UserSocket
      |> socket("user_id", %{some: :assign})
      |> subscribe_and_join(AlfredWeb.EmacsChannel, "emacs:lobby")

    %{socket: socket}
  end

  test "ping replies with status ok", %{socket: socket} do
    ref = push(socket, "ping", %{"hello" => "there"})
    assert_reply ref, :ok, %{"hello" => "there"}
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from!(socket, "broadcast", %{"some" => "data"})
    assert_push "broadcast", %{"some" => "data"}
  end
end
