defmodule Alfred.Services.Spotify do
  alias Alfred.Core

  def pause_music do
    access_token = get_access_token()
    url = "https://api.spotify.com/v1/me/player/pause"
    Req.put(url, body: "", headers: [{"authorization", "Bearer #{access_token}"}])
  end

  def resume_music do
    access_token = get_access_token()
    url = "https://api.spotify.com/v1/me/player/play"
    Req.put(url, body: "", headers: [{"authorization", "Bearer #{access_token}"}])
  end

  defp get_access_token do
    Core.get_config_value!("secret.spotify.access_token")
  end
end
