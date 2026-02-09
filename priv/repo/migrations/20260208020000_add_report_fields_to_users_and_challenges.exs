defmodule HeadsUp.Repo.Migrations.AddReportFieldsToUsersAndChallenges do
  use Ecto.Migration

  def up do
    # Add report fields to users table
    execute "ALTER TABLE users ADD COLUMN IF NOT EXISTS report_count integer DEFAULT 0"
    execute "ALTER TABLE users ADD COLUMN IF NOT EXISTS moderation_status varchar DEFAULT 'clean'"

    # Add report fields to challenges table
    execute "ALTER TABLE challenges ADD COLUMN IF NOT EXISTS report_count integer DEFAULT 0"
    execute "ALTER TABLE challenges ADD COLUMN IF NOT EXISTS moderation_status varchar DEFAULT 'clean'"

    # Add new target columns to reports table
    alter table(:reports) do
      add_if_not_exists :reported_user_id, references(:users, on_delete: :delete_all)
      add_if_not_exists :challenge_id, references(:challenges, on_delete: :delete_all)
    end

    # One report per reporter per user
    create unique_index(:reports, [:reported_user_id, :user_id],
      where: "reported_user_id IS NOT NULL",
      name: :reports_reported_user_id_user_id_index
    )

    # One report per reporter per challenge
    create unique_index(:reports, [:challenge_id, :user_id],
      where: "challenge_id IS NOT NULL",
      name: :reports_challenge_id_user_id_index
    )

    create index(:reports, [:reported_user_id])
    create index(:reports, [:challenge_id])
  end

  def down do
    drop_if_exists index(:reports, [:challenge_id])
    drop_if_exists index(:reports, [:reported_user_id])
    drop_if_exists unique_index(:reports, [:challenge_id, :user_id], name: :reports_challenge_id_user_id_index)
    drop_if_exists unique_index(:reports, [:reported_user_id, :user_id], name: :reports_reported_user_id_user_id_index)

    alter table(:reports) do
      remove :reported_user_id
      remove :challenge_id
    end

    alter table(:users) do
      remove :report_count
      remove :moderation_status
    end

    alter table(:challenges) do
      remove :report_count
      remove :moderation_status
    end
  end
end
