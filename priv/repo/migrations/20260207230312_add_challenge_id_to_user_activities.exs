defmodule HeadsUp.Repo.Migrations.AddChallengeIdToUserActivities do
  use Ecto.Migration

  def change do
    alter table(:user_activities) do
      add :challenge_id, references(:challenges, on_delete: :nilify_all)
    end

    create index(:user_activities, [:challenge_id])
  end
end
