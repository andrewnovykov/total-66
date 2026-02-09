defmodule HeadsUp.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "conversations" do
    field :last_message_at, :utc_datetime

    belongs_to :user1, HeadsUp.Users
    belongs_to :user2, HeadsUp.Users
    has_many :messages, HeadsUp.Message

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:user1_id, :user2_id, :last_message_at])
    |> validate_required([:user1_id, :user2_id])
    |> foreign_key_constraint(:user1_id)
    |> foreign_key_constraint(:user2_id)
    |> unique_constraint([:user1_id, :user2_id])
    |> validate_different_users()
    |> ensure_ordered_ids()
  end

  defp validate_different_users(changeset) do
    user1_id = get_field(changeset, :user1_id)
    user2_id = get_field(changeset, :user2_id)

    if user1_id && user2_id && user1_id == user2_id do
      add_error(changeset, :user2_id, "cannot message yourself")
    else
      changeset
    end
  end

  defp ensure_ordered_ids(changeset) do
    user1_id = get_field(changeset, :user1_id)
    user2_id = get_field(changeset, :user2_id)

    if user1_id && user2_id && user1_id > user2_id do
      changeset
      |> put_change(:user1_id, user2_id)
      |> put_change(:user2_id, user1_id)
    else
      changeset
    end
  end
end
