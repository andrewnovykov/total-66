defmodule HeadsUp.Repo.Migrations.CreateGroups do
  use Ecto.Migration

  def change do
    create table(:groups) do
      add :name, :string
      add :description, :text
      add :image_path, :string
      add :status, :string

      timestamps(type: :utc_datetime)
    end
  end
end
