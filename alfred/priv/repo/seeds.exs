# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Alfred.Repo.insert!(%Alfred.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Alfred.Commands.Command
alias Alfred.Core.ConfigParam

utc_now = DateTime.utc_now() |> DateTime.truncate(:second)

commands =
  [
    %{trigger: "ping", type: :text, result: "pong"}
  ]
  |> Enum.map(&Map.put(&1, :inserted_at, utc_now))
  |> Enum.map(&Map.put(&1, :updated_at, utc_now))

config_params =
  [
    "error_image",
    "success_image",
    "git_project_dir",
    "flags.git",
    "flags.spotify",
    "secret.spotify.access_token",
    "secret.spotify.refresh_token",
    "secret.twitch.access_token",
    "secret.twitch.refresh_token",
    "twitch.user_id"
  ]
  |> Enum.map(&%{key: &1, value: ""})
  |> Enum.map(&Map.put(&1, :inserted_at, utc_now))
  |> Enum.map(&Map.put(&1, :updated_at, utc_now))

Alfred.Repo.insert_all(Command, commands)
Alfred.Repo.insert_all(ConfigParam, config_params)
