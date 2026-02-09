defmodule HeadsUp.Repo.Migrations.RemoveCategoriesPhasesAddTaskType do
  use Ecto.Migration

  def up do
    # 1. Add task_type and order_index to challenge_tasks
    alter table(:challenge_tasks) do
      add :task_type, :string, default: "mandatory"
      add :order_index, :integer, default: 0
    end

    # 2. Add approval_status to challenges
    alter table(:challenges) do
      add :approval_status, :string, default: "approved"
    end

    # 3. Remove category_id from challenges
    drop_if_exists index(:challenges, [:category_id])

    alter table(:challenges) do
      remove_if_exists :category_id, :integer
    end

    # 4. Drop tables (order matters for FK constraints)
    drop_if_exists table(:challenge_step_progress)
    drop_if_exists table(:challenge_steps)
    drop_if_exists table(:challenge_phases)
    drop_if_exists table(:challenge_categories)
  end

  def down do
    # Recreate tables
    create table(:challenge_categories) do
      add :name, :string, null: false
      add :description, :text
      add :icon, :string
      add :color, :string
      add :order, :integer, default: 0
      add :status, :string, default: "active"
      timestamps(type: :utc_datetime)
    end

    create table(:challenge_phases) do
      add :title, :string, null: false
      add :description, :text
      add :order_index, :integer, default: 0
      add :challenge_id, references(:challenges, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end

    create table(:challenge_steps) do
      add :title, :string, null: false
      add :description, :text
      add :order_index, :integer, default: 0
      add :phase_id, references(:challenge_phases, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end

    create table(:challenge_step_progress) do
      add :participant_id, references(:challenge_participants, on_delete: :delete_all), null: false
      add :step_id, references(:challenge_steps, on_delete: :delete_all), null: false
      add :status, :string, default: "completed"
      add :completed_at, :utc_datetime
      timestamps(type: :utc_datetime)
    end

    # Add back category_id
    alter table(:challenges) do
      add :category_id, references(:challenge_categories, on_delete: :nilify_all)
    end

    create index(:challenges, [:category_id])

    # Remove added columns
    alter table(:challenges) do
      remove :approval_status
    end

    alter table(:challenge_tasks) do
      remove :task_type
      remove :order_index
    end
  end
end
