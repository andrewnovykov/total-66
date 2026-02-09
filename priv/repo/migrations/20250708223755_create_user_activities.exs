defmodule HeadsUp.Repo.Migrations.CreateUserActivities do
  use Ecto.Migration

  def change do
    create table(:user_activities) do
      add :activity_type, :string, null: false
      add :xp_change, :integer, null: false, default: 0
      add :description, :text
      add :metadata, :map, default: %{}

      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :goal_id, references(:goals, on_delete: :nilify_all)
      add :post_id, references(:goal_posts, on_delete: :nilify_all)
      add :like_id, :bigint
      add :follow_id, :bigint

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:user_activities, [:user_id])
    create index(:user_activities, [:activity_type])
    create index(:user_activities, [:inserted_at])
    create index(:user_activities, [:user_id, :inserted_at])
  end
end
