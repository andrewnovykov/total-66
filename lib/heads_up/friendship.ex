defmodule HeadsUp.Friendship do
  use Ecto.Schema
  import Ecto.Changeset

  schema "friendships" do
    # pending, accepted, declined, blocked
    field :status, :string, default: "pending"

    belongs_to :user, HeadsUp.Users
    belongs_to :friend, HeadsUp.Users

    timestamps()
  end

  @doc false
  def changeset(friendship, attrs) do
    friendship
    |> cast(attrs, [:status, :user_id, :friend_id])
    |> validate_required([:user_id, :friend_id])
    |> validate_inclusion(:status, ["pending", "accepted", "declined", "blocked"])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:friend_id)
    |> unique_constraint([:user_id, :friend_id])
    |> validate_not_self_friend()
  end

  defp validate_not_self_friend(changeset) do
    user_id = get_field(changeset, :user_id)
    friend_id = get_field(changeset, :friend_id)

    if user_id && friend_id && user_id == friend_id do
      add_error(changeset, :friend_id, "cannot be friends with yourself")
    else
      changeset
    end
  end
end
