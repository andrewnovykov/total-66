defmodule HeadsUp.Repo.Migrations.CreateDailyCheckIns do
  use Ecto.Migration

  def change do
    create table(:daily_check_ins) do
      add :participant_id, references(:challenge_participants, on_delete: :delete_all),
        null: false

      add :challenge_id, references(:challenges, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      add :day_number, :integer, null: false
      add :completed_date, :date, null: false

      add :total_tasks, :integer, null: false, default: 0
      add :completed_tasks, :integer, null: false, default: 0
      add :failed_tasks, :integer, null: false, default: 0
      add :skipped_tasks, :integer, null: false, default: 0

      add :note, :text

      timestamps(type: :utc_datetime)
    end

    # One check-in per participant per day
    create unique_index(:daily_check_ins, [:participant_id, :completed_date])

    # For challenge feed queries (newest first)
    create index(:daily_check_ins, [:challenge_id, :inserted_at])

    # For user activity feed queries
    create index(:daily_check_ins, [:user_id, :inserted_at])
  end
end
