defmodule HeadsUp.Goal do
  use Ecto.Schema
  import Ecto.Changeset

  schema "goals" do
    field :title, :string
    field :description, :string
    field :big_description, :string

    field :status, Ecto.Enum,
      values: [:active, :completed, :paused, :cancelled, :frozen, :failed, :deleted],
      default: :active

    field :privacy, Ecto.Enum, values: [:public, :private, :friends], default: :public
    field :target_date, :utc_datetime
    field :progress, :integer, default: 0
    field :image_path, :string
    field :failure_reason, :string
    field :failed_at, :utc_datetime
    field :deleted_at, :utc_datetime
    field :is_frozen, :boolean, default: false
    field :report_count, :integer, default: 0
    field :moderation_status, :string, default: "clean"

    belongs_to :group, HeadsUp.Group
    belongs_to :user, HeadsUp.Users

    has_many :goal_likes, HeadsUp.GoalLike
    has_many :goal_subscriptions, HeadsUp.GoalSubscription
    has_many :goal_posts, HeadsUp.Goals.GoalPost
    has_many :goal_steps, HeadsUp.GoalStep, preload_order: [asc: :order]
    has_many :reports, HeadsUp.Reports.Report
    has_many :likes, through: [:goal_likes, :user]
    has_many :subscribers, through: [:goal_subscriptions, :user]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(goal, attrs) do
    goal
    |> cast(attrs, [
      :title,
      :description,
      :big_description,
      :status,
      :privacy,
      :target_date,
      :progress,
      :image_path,
      :failure_reason,
      :failed_at,
      :deleted_at,
      :is_frozen,
      :report_count,
      :moderation_status,
      :group_id,
      :user_id
    ])
    |> validate_required([:title, :group_id, :user_id, :target_date])
    |> validate_inclusion(:progress, 0..100)
    |> validate_failure_reason()
    |> foreign_key_constraint(:group_id)
    |> foreign_key_constraint(:user_id)
  end

  # Custom validation to ensure failure_reason is provided when goal is failed
  defp validate_failure_reason(changeset) do
    failure_reason = get_field(changeset, :failure_reason)
    failed_at = get_field(changeset, :failed_at)
    status = get_field(changeset, :status)

    case {status, failed_at, failure_reason} do
      {:failed, _, nil} ->
        add_error(changeset, :failure_reason, "is required when goal is marked as failed")

      {:failed, _, ""} ->
        add_error(changeset, :failure_reason, "is required when goal is marked as failed")

      {_, date, nil} when not is_nil(date) ->
        add_error(changeset, :failure_reason, "is required when goal is marked as failed")

      {_, date, ""} when not is_nil(date) ->
        add_error(changeset, :failure_reason, "is required when goal is marked as failed")

      _ ->
        changeset
    end
  end
end
