defmodule HeadsUp.Repo.Migrations.AddAboutToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :about, :string
    end
  end
end
