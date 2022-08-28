defmodule AlfredWeb.SessionPlug do
  import Plug.Conn
  import Phoenix.Controller
  alias AlfredWeb.Router.Helpers, as: Routes

  def init(opts), do: opts

  def call(conn, _opts) do
    if get_session(conn, :authenticated) do
      conn
    else
      conn
      |> put_flash(:warn, "Must log in to enter admin")
      |> redirect(to: Routes.auth_path(conn, :new_session))
    end
  end
end
