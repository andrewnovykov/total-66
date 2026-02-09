defmodule HeadsUp.Repo.Migrations.AddDayRangeToChallengePhases do
  use Ecto.Migration

  def change do
    alter table(:challenge_phases) do
      # For Official (template) challenges: phases defined by day numbers
      add :start_day, :integer
      add :end_day, :integer
    end
  end
end
