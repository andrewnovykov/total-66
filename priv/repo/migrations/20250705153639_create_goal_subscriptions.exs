defmodule HeadsUp.Repo.Migrations.CreateGoalSubscriptions do
  use Ecto.Migration

  def change do
    create table(:goal_subscriptions) do
      add :goal_id, references(:goals, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:goal_subscriptions, [:goal_id, :user_id])
    create index(:goal_subscriptions, [:goal_id])
    create index(:goal_subscriptions, [:user_id])
  end
end
