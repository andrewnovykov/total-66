defmodule HeadsUp.UserFollow do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_follows" do
    belongs_to :follower, HeadsUp.Users
    belongs_to :following, HeadsUp.Users

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_follow, attrs) do
    user_follow
    |> cast(attrs, [:follower_id, :following_id])
    |> validate_required([:follower_id, :following_id])
    |> foreign_key_constraint(:follower_id)
    |> foreign_key_constraint(:following_id)
    |> unique_constraint([:follower_id, :following_id])
    |> validate_not_self_follow()
  end

  defp validate_not_self_follow(changeset) do
    follower_id = get_field(changeset, :follower_id)
    following_id = get_field(changeset, :following_id)

    if follower_id == following_id do
      add_error(changeset, :following_id, "cannot follow yourself")
    else
      changeset
    end
  end
end
