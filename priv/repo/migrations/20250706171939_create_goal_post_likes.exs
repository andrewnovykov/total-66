defmodule HeadsUp.Repo.Migrations.CreateGoalPostLikes do
  use Ecto.Migration

  def change do
    create table(:goal_post_likes) do
      add :goal_post_id, references(:goal_posts, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:goal_post_likes, [:goal_post_id, :user_id])
    create index(:goal_post_likes, [:goal_post_id])
    create index(:goal_post_likes, [:user_id])
  end
end
