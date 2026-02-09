defmodule HeadsUp.Repo.Migrations.AddFailedStatusToChallenges do
  use Ecto.Migration

  def change do
    alter table(:challenges) do
      add :failure_reason, :text
      add :failed_at, :utc_datetime
    end

    alter table(:challenge_participants) do
      add :failure_reason, :text
      add :failed_at, :utc_datetime
    end
  end
end
