defmodule AlfredWeb.SpotifyController do
  use AlfredWeb, :controller

  alias Alfred.Core

  require Logger

  def authenticate(conn, params) do
    {conn, path} =
      case Spotify.Authentication.authenticate(conn, params) do
        {:ok, conn} ->
          # Spotify lib stores token into cookies
          %{
            "spotify_access_token" => access_token,
            "spotify_refresh_token" => refresh_token
          } = Map.take(conn.cookies, ["spotify_access_token", "spotify_refresh_token"])

          Core.update_config_param("secret.spotify.access_token", access_token)
          Core.update_config_param("secret.spotify.refresh_token", refresh_token)

          conn = put_status(conn, 301)
          {conn, "/admin"}

        {:error, reason, conn} ->
          Logger.error("Error when trying to login #{inspect(reason)}")
          {conn, "/admin/"}
      end

    redirect(conn, to: path)
  end

  def authorize(conn, _params) do
    redirect(conn, external: Spotify.Authorization.url())
  end
end
