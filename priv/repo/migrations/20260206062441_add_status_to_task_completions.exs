defmodule HeadsUp.Repo.Migrations.AddStatusToTaskCompletions do
  use Ecto.Migration

  def change do
    alter table(:challenge_task_completions) do
      # Status: accomplished (completed) or failed
      add :status, :string, default: "accomplished"
    end
  end
end
