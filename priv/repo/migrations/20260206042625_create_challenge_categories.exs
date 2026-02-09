defmodule HeadsUp.Repo.Migrations.CreateChallengeCategories do
  use Ecto.Migration

  def change do
    create table(:challenge_categories) do
      add :name, :string, null: false
      add :description, :text
      add :image_path, :string
      add :status, :string, default: "active", null: false
      add :order, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:challenge_categories, [:name])
    create index(:challenge_categories, [:status])
    create index(:challenge_categories, [:order])

    # Add category_id to challenges table (replacing group_id reference)
    alter table(:challenges) do
      add :category_id, references(:challenge_categories, on_delete: :nilify_all)
    end

    create index(:challenges, [:category_id])
  end
end
