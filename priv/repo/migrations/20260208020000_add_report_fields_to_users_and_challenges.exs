defmodule HeadsUp.Repo.Migrations.AddReportFieldsToUsersAndChallenges do
  use Ecto.Migration

  def up do
    # Add report fields to users table
    execute "ALTER TABLE users ADD COLUMN IF NOT EXISTS report_count integer DEFAULT 0"
    execute "ALTER TABLE users ADD COLUMN IF NOT EXISTS moderation_status varchar DEFAULT 'clean'"

    # Add report fields to challenges table
    execute "ALTER TABLE challenges ADD COLUMN IF NOT EXISTS report_count integer DEFAULT 0"
    execute "ALTER TABLE challenges ADD COLUMN IF NOT EXISTS moderation_status varchar DEFAULT 'clean'"
  end

  def down do
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
