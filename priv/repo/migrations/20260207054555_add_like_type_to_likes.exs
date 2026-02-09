defmodule HeadsUp.Repo.Migrations.AddLikeTypeToLikes do
  use Ecto.Migration

  def change do
    # Add like_type to goal_likes (default "like" for existing rows)
    alter table(:goal_likes) do
      add :like_type, :string, default: "like", null: false
    end

    # Add like_type to goal_post_likes
    alter table(:goal_post_likes) do
      add :like_type, :string, default: "like", null: false
    end

    # Add like_type to check_in_likes
    alter table(:check_in_likes) do
      add :like_type, :string, default: "like", null: false
    end
  end
end
