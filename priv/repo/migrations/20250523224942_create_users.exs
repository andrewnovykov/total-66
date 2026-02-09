defmodule HeadsUp.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :user_name, :string
      add :name, :string
      add :bio, :string
      add :level, :integer
      add :image_path, :string

      timestamps(type: :utc_datetime)
    end
  end
end
