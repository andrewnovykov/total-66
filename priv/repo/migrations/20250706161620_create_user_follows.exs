defmodule HeadsUp.Repo.Migrations.CreateUserFollows do
  use Ecto.Migration

  def change do
    create table(:user_follows) do
      add :follower_id, references(:users, on_delete: :delete_all), null: false
      add :following_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:user_follows, [:follower_id])
    create index(:user_follows, [:following_id])
    create unique_index(:user_follows, [:follower_id, :following_id])
  end
end
