defmodule HeadsUp.GoalPostLike do
  use Ecto.Schema
  import Ecto.Changeset

  schema "goal_post_likes" do
    field :like_type, :string, default: "like"
    belongs_to :goal_post, HeadsUp.Goals.GoalPost
    belongs_to :user, HeadsUp.Users

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(goal_post_like, attrs) do
    goal_post_like
    |> cast(attrs, [:goal_post_id, :user_id, :like_type])
    |> validate_required([:goal_post_id, :user_id])
    |> validate_inclusion(:like_type, ["like", "dislike"])
    |> foreign_key_constraint(:goal_post_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:goal_post_id, :user_id])
  end
end
