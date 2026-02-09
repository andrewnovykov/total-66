defmodule HeadsUp.Repo.Migrations.CreateFriendships do
  use Ecto.Migration

  def change do
    create table(:friendships) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :friend_id, references(:users, on_delete: :delete_all), null: false
      add :status, :string, default: "pending", null: false

      timestamps()
    end

    # Create indexes for performance
    create index(:friendships, [:user_id])
    create index(:friendships, [:friend_id])
    create index(:friendships, [:status])

    # Ensure unique friendships (prevent duplicate friend requests)
    create unique_index(:friendships, [:user_id, :friend_id])
  end
end
