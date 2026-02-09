defmodule HeadsUp.Repo.Migrations.AddXpToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :xp, :integer, default: 0
    end

    create index(:users, [:xp])
  end
end
