defmodule HeadsUp.Repo.Migrations.CreateGoalSteps do
  use Ecto.Migration

  def change do
    create table(:goal_steps) do
      add :title, :string, null: false
      add :completed, :boolean, default: false, null: false
      add :order, :integer, null: false
      add :goal_id, references(:goals, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:goal_steps, [:goal_id])
    create index(:goal_steps, [:goal_id, :order])
  end
end
