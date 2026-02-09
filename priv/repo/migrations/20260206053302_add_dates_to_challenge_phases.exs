defmodule HeadsUp.Repo.Migrations.AddDatesToChallengePhases do
  use Ecto.Migration

  def change do
    alter table(:challenge_phases) do
      add :start_date, :date
      add :end_date, :date
    end
  end
end
