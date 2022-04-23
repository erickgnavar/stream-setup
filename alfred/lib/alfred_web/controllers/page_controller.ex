defmodule AlfredWeb.PageController do
  use AlfredWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
