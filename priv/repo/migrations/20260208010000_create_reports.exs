defmodule HeadsUp.Repo.Migrations.CreateReports do
  use Ecto.Migration

  def up do
    # Drop old reports table if it exists (from previous dev iterations)
    execute "DROP TABLE IF EXISTS reports CASCADE"

    create table(:reports) do
      add :reason, :string, null: false
      add :description, :string
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :reported_user_id, references(:users, on_delete: :delete_all)
      add :challenge_id, references(:challenges, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:reports, [:user_id])
    create index(:reports, [:reported_user_id])
    create index(:reports, [:challenge_id])

    # One report per user per reported_user
    create unique_index(:reports, [:reported_user_id, :user_id],
      where: "reported_user_id IS NOT NULL",
      name: :reports_reported_user_id_user_id_index
    )

    # One report per user per challenge
    create unique_index(:reports, [:challenge_id, :user_id],
      where: "challenge_id IS NOT NULL",
      name: :reports_challenge_id_user_id_index
    )
  end

  def down do
    drop table(:reports)
  end
end
