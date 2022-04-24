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

utc_now = DateTime.utc_now() |> DateTime.truncate(:second)

commands =
  [
    %{trigger: "ping", type: :text, result: "pong"}
  ]
  |> Enum.map(&Map.put(&1, :inserted_at, utc_now))
  |> Enum.map(&Map.put(&1, :updated_at, utc_now))

Alfred.Repo.insert_all(Command, commands)
