defmodule HeadsUp.Repo.Migrations.CreateCheckInLikesAndComments do
  use Ecto.Migration

  def change do
    create table(:check_in_likes) do
      add :check_in_id, references(:daily_check_ins, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:check_in_likes, [:check_in_id, :user_id])
    create index(:check_in_likes, [:check_in_id])
    create index(:check_in_likes, [:user_id])

    create table(:check_in_comments) do
      add :content, :text, null: false
      add :check_in_id, references(:daily_check_ins, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:check_in_comments, [:check_in_id])
    create index(:check_in_comments, [:user_id])
  end
end
