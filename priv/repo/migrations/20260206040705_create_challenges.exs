defmodule HeadsUp.Repo.Migrations.CreateChallenges do
  use Ecto.Migration

  def change do
    create table(:challenges) do
      add :title, :string, null: false
      add :description, :text
      add :type, :string, null: false, default: "custom"
      add :visibility, :string, null: false, default: "public"
      add :status, :string, null: false, default: "active"
      add :image_path, :string
      add :start_date, :date
      add :end_date, :date
      add :creator_user_id, references(:users, on_delete: :delete_all), null: false
      # category_id will be added by create_challenge_categories migration

      timestamps(type: :utc_datetime)
    end

    create index(:challenges, [:creator_user_id])
    create index(:challenges, [:type])
    create index(:challenges, [:visibility])
    create index(:challenges, [:status])

    # Challenge tasks (for all challenges with schedules)
    create table(:challenge_tasks) do
      add :title, :string, null: false
      add :description, :text
      add :schedule_type, :string, null: false, default: "daily"
      add :schedule_weekdays, {:array, :string}, default: []
      add :challenge_id, references(:challenges, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:challenge_tasks, [:challenge_id])

    # Challenge participants
    create table(:challenge_participants) do
      add :status, :string, null: false, default: "active"
      add :joined_at, :utc_datetime, null: false
      add :completed_at, :utc_datetime
      add :challenge_id, references(:challenges, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:challenge_participants, [:challenge_id, :user_id])
    create index(:challenge_participants, [:user_id])
    create index(:challenge_participants, [:status])

    # Challenge task completions (for all challenges)
    create table(:challenge_task_completions) do
      add :completed_date, :date, null: false
      add :completed_at, :utc_datetime

      add :participant_id, references(:challenge_participants, on_delete: :delete_all),
        null: false

      add :task_id, references(:challenge_tasks, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:challenge_task_completions, [:participant_id, :task_id, :completed_date])
    create index(:challenge_task_completions, [:participant_id])
  end
end
