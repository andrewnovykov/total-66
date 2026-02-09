defmodule HeadsUp.Repo.Migrations.UpdateChallengeDatesToDuration do
  use Ecto.Migration

  def change do
    alter table(:challenges) do
      # For official challenges: duration in days (e.g., 30, 50, 100)
      add :duration_days, :integer
      # For community challenges that become templates
      add :is_template, :boolean, default: false
    end

    alter table(:challenge_participants) do
      # Each participant has their own start/end dates
      add :start_date, :date
      add :end_date, :date
    end
  end
end
