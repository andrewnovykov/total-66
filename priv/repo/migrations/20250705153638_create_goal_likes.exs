defmodule HeadsUp.Repo.Migrations.CreateGoalLikes do
  use Ecto.Migration

  def change do
    create table(:goal_likes) do
      add :goal_id, references(:goals, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:goal_likes, [:goal_id, :user_id])
    create index(:goal_likes, [:goal_id])
    create index(:goal_likes, [:user_id])
  end
end
