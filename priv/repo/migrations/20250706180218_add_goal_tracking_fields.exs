defmodule HeadsUp.Repo.Migrations.AddGoalTrackingFields do
  use Ecto.Migration

  def change do
    # Add new fields for tracking failure and deletion
    alter table(:goals) do
      add :failure_reason, :text
      add :failed_at, :utc_datetime
      add :deleted_at, :utc_datetime
      add :is_frozen, :boolean, default: false
    end

    # Add index for soft deleted goals
    create index(:goals, [:deleted_at])
    # Add index for frozen goals
    create index(:goals, [:is_frozen])
  end
end
