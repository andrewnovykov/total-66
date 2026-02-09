defmodule HeadsUp.Repo.Migrations.AddStepIdToGoalPosts do
  use Ecto.Migration

  def change do
    alter table(:goal_posts) do
      add :step_id, references(:goal_steps, on_delete: :nilify_all)
    end

    create index(:goal_posts, [:step_id])
  end
end
