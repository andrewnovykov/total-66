defmodule HeadsUp.GoalSubscription do
  use Ecto.Schema
  import Ecto.Changeset

  schema "goal_subscriptions" do
    belongs_to :goal, HeadsUp.Goal
    belongs_to :user, HeadsUp.Users

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(goal_subscription, attrs) do
    goal_subscription
    |> cast(attrs, [:goal_id, :user_id])
    |> validate_required([:goal_id, :user_id])
    |> unique_constraint([:goal_id, :user_id])
    |> foreign_key_constraint(:goal_id)
    |> foreign_key_constraint(:user_id)
  end
end
