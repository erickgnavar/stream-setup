defmodule Alfred.Repo do
  use Ecto.Repo,
    otp_app: :alfred,
    adapter: Ecto.Adapters.SQLite3
end
