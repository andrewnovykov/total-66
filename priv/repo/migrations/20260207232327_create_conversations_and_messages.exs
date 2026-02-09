defmodule HeadsUp.Repo.Migrations.CreateConversationsAndMessages do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      add :user1_id, references(:users, on_delete: :delete_all), null: false
      add :user2_id, references(:users, on_delete: :delete_all), null: false
      add :last_message_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    # Ensure user1_id < user2_id for consistent ordering
    create unique_index(:conversations, [:user1_id, :user2_id])
    create index(:conversations, [:user1_id])
    create index(:conversations, [:user2_id])
    create index(:conversations, [:last_message_at])

    create table(:messages) do
      add :content, :text, null: false
      add :read, :boolean, default: false, null: false
      add :conversation_id, references(:conversations, on_delete: :delete_all), null: false
      add :sender_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:conversation_id, :inserted_at])
    create index(:messages, [:sender_id])
    create index(:messages, [:conversation_id, :read])
  end
end
