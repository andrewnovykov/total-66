defmodule HeadsUp.Repo.Migrations.CreateUserLevels do
  use Ecto.Migration

  def change do
    create table(:user_levels) do
      add :level, :integer, null: false, default: 1
      add :xp, :integer, null: false, default: 0
      add :level_name, :string, null: false, default: "Seastar"
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_levels, [:user_id])
    create index(:user_levels, [:level])
    create index(:user_levels, [:xp])
  end
end
