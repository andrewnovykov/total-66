defmodule HeadsUp.Repo.Migrations.CreateGoalPosts do
  use Ecto.Migration

  def change do
    create table(:goal_posts) do
      add :content, :text
      add :post_type, :string
      add :image_path, :string
      add :goal_id, references(:goals, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:goal_posts, [:goal_id])
    create index(:goal_posts, [:user_id])
  end
end
