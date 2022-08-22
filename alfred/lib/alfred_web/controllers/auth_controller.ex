defmodule AlfredWeb.AuthController do
  use AlfredWeb, :controller

  alias Alfred.Core
  require Logger

  def callback(%{assigns: %{ueberauth_failure: fails}} = conn, _params) do
    Logger.debug(fails)

    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/admin")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    # TODO: separate by provider
    Core.update_config_param("twitch.access_token", auth.credentials.token)
    Core.update_config_param("twitch.refresh_token", auth.credentials.refresh_token)
    Core.update_config_param("twitch.user_id", auth.uid)

    conn
    |> put_flash(:info, "Successfully authenticated.")
    |> redirect(to: "/admin")
  end
end
