defmodule HeadsUp.GoalLike do
  use Ecto.Schema
  import Ecto.Changeset

  schema "goal_likes" do
    field :like_type, :string, default: "like"
    belongs_to :goal, HeadsUp.Goal
    belongs_to :user, HeadsUp.Users

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(goal_like, attrs) do
    goal_like
    |> cast(attrs, [:goal_id, :user_id, :like_type])
    |> validate_required([:goal_id, :user_id])
    |> validate_inclusion(:like_type, ["like", "dislike"])
    |> unique_constraint([:goal_id, :user_id])
    |> foreign_key_constraint(:goal_id)
    |> foreign_key_constraint(:user_id)
  end
end
