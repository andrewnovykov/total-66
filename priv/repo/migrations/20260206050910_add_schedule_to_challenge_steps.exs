defmodule HeadsUp.Repo.Migrations.AddScheduleToChallengeSteps do
  use Ecto.Migration

  def change do
    alter table(:challenge_steps) do
      add :schedule_type, :string, default: "daily"
      add :schedule_weekdays, {:array, :string}, default: []
    end
  end
end
