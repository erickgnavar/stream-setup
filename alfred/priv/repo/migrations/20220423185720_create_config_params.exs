defmodule Alfred.Repo.Migrations.CreateConfigParams do
  use Ecto.Migration

  def change do
    create table(:config_params) do
      add :key, :string, null: false
      add :value, :string, null: false

      timestamps()
    end
  end
end
