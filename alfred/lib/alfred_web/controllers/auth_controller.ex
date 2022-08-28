defmodule AlfredWeb.AuthController do
  use AlfredWeb, :controller

  alias Alfred.Core
  require Logger

  @session_key :authenticated

  def new_session(conn, _params) do
    render(conn, "login.html")
  end

  def create_session(conn, %{"password" => raw_password}) do
    with %{value: hashed_password} <- Core.get_config_param("secret.admin.password"),
         true <- Bcrypt.verify_pass(raw_password, hashed_password) do
      conn
      |> put_session(@session_key, true)
      |> put_flash(:info, "Successfully authenticated.")
      |> redirect(to: "/admin")
    else
      false ->
        conn
        |> put_flash(:warn, "Wrong password")
        |> redirect(to: Routes.auth_path(conn, :new_session))

      nil ->
        conn
        |> put_flash(:warn, "No password set")
        |> redirect(to: Routes.auth_path(conn, :new_session))
    end
  end

  def logout(conn, _params) do
    conn
    |> delete_session(@session_key)
    |> put_flash(:info, "Logged out")
    |> redirect(to: Routes.auth_path(conn, :new_session))
  end

  def callback(%{assigns: %{ueberauth_failure: fails}} = conn, _params) do
    Logger.debug(fails)

    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/admin")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    # TODO: separate by provider
    Core.update_config_param("secret.twitch.access_token", auth.credentials.token)
    Core.update_config_param("secret.twitch.refresh_token", auth.credentials.refresh_token)
    Core.update_config_param("twitch.user_id", auth.uid)

    conn
    |> put_flash(:info, "Successfully authenticated.")
    |> redirect(to: "/admin")
  end
end
