defmodule HeadsUp.Repo.Migrations.AddStatusToChallengeStepProgress do
  use Ecto.Migration

  def change do
    alter table(:challenge_step_progress) do
      add :status, :string, default: "completed", null: false
    end
  end
end
