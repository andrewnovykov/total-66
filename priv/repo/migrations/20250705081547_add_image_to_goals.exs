defmodule HeadsUp.Repo.Migrations.AddImageToGoals do
  use Ecto.Migration

  def change do
    alter table(:goals) do
      add :image_path, :string
    end
  end
end
