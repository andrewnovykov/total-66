defmodule HeadsUp.Repo.Migrations.AddPrivacyToGoals do
  use Ecto.Migration

  def change do
    alter table(:goals) do
      add :privacy, :string, default: "public", null: false
    end

    create index(:goals, [:privacy])
  end
end
