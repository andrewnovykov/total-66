defmodule HeadsUp.UserActivity do
  use Ecto.Schema
  import Ecto.Changeset

  @activity_types [
    "goal_created",
    "goal_completed",
    "goal_failed",
    "goal_frozen",
    "goal_deleted",
    "goal_updated",
    "post_created",
    "post_liked",
    "post_received_like",
    "user_followed",
    "user_received_follow",
    "friend_request_sent",
    "friend_request_accepted",
    "daily_login",
    "goal_step_completed",
    # Challenge activities
    "challenge_created",
    "challenge_joined",
    "challenge_completed",
    "challenge_failed",
    "challenge_started",
    "challenge_shared",
    "challenge_cancelled",
    "daily_task_completed",
    "daily_task_failed",
    "daily_check_in_submitted"
  ]

  schema "user_activities" do
    field :activity_type, :string
    field :xp_change, :integer, default: 0
    field :description, :string
    field :metadata, :map, default: %{}

    belongs_to :user, HeadsUp.Users
    belongs_to :goal, HeadsUp.Goal
    belongs_to :post, HeadsUp.Goals.GoalPost
    belongs_to :challenge, HeadsUp.Challenges.Challenge
    field :like_id, :integer
    field :follow_id, :integer

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(user_activity, attrs) do
    user_activity
    |> cast(attrs, [
      :activity_type,
      :xp_change,
      :description,
      :metadata,
      :user_id,
      :goal_id,
      :post_id,
      :challenge_id,
      :like_id,
      :follow_id
    ])
    |> validate_required([:activity_type, :user_id])
    |> validate_inclusion(:activity_type, @activity_types)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:goal_id)
    |> foreign_key_constraint(:post_id)
  end

  def activity_types, do: @activity_types
end
