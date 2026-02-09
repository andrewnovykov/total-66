defmodule HeadsUp.Repo.Migrations.CreateReports do
  use Ecto.Migration

  def up do
    # Drop old reports table if it exists (from previous dev iterations)
    execute "DROP TABLE IF EXISTS reports CASCADE"

    create table(:reports) do
      add :reason, :string, null: false
      add :description, :string
      add :goal_id, references(:goals, on_delete: :delete_all)
      add :post_id, references(:goal_posts, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    # One report per user per goal
    create unique_index(:reports, [:goal_id, :user_id],
      where: "goal_id IS NOT NULL",
      name: :reports_goal_id_user_id_index
    )

    # One report per user per post
    create unique_index(:reports, [:post_id, :user_id],
      where: "post_id IS NOT NULL",
      name: :reports_post_id_user_id_index
    )

    create index(:reports, [:goal_id])
    create index(:reports, [:post_id])
    create index(:reports, [:user_id])

    # Add report_count and moderation_status to goals (IF NOT EXISTS for dev db)
    execute "ALTER TABLE goals ADD COLUMN IF NOT EXISTS report_count integer DEFAULT 0"
    execute "ALTER TABLE goals ADD COLUMN IF NOT EXISTS moderation_status varchar DEFAULT 'clean'"

    # Add report_count and moderation_status to goal_posts
    execute "ALTER TABLE goal_posts ADD COLUMN IF NOT EXISTS report_count integer DEFAULT 0"
    execute "ALTER TABLE goal_posts ADD COLUMN IF NOT EXISTS moderation_status varchar DEFAULT 'clean'"
  end

  def down do
    drop table(:reports)

    alter table(:goals) do
      remove :report_count
      remove :moderation_status
    end

    alter table(:goal_posts) do
      remove :report_count
      remove :moderation_status
    end
  end
end
