defmodule Alfred.Repo.Migrations.CreateCommands do
  use Ecto.Migration

  def change do
    create table(:commands) do
      add :trigger, :string, null: false
      add :type, :string, null: false
      add :result, :string, null: false

      timestamps()
    end
  end
end
