defmodule HeadsUp.Repo.Migrations.CreateGoalComments do
  use Ecto.Migration

  def change do
    create table(:goal_comments) do
      add :content, :text, null: false
      add :goal_post_id, references(:goal_posts, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:goal_comments, [:goal_post_id])
    create index(:goal_comments, [:user_id])
  end
end
