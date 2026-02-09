defmodule HeadsUp.Repo.Migrations.CreateGoals do
  use Ecto.Migration

  def change do
    create table(:goals) do
      add :title, :string, null: false
      add :description, :text
      add :status, :string, default: "active"
      add :target_date, :utc_datetime
      add :progress, :integer, default: 0
      add :group_id, references(:groups, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:goals, [:group_id])
    create index(:goals, [:user_id])
    create index(:goals, [:status])
  end
end
