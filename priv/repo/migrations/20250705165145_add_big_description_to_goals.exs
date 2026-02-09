defmodule HeadsUp.Repo.Migrations.AddBigDescriptionToGoals do
  use Ecto.Migration

  def change do
    alter table(:goals) do
      add :big_description, :text
    end
  end
end
