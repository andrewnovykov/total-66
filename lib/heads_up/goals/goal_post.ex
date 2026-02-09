defmodule HeadsUp.Goals.GoalPost do
  use Ecto.Schema
  import Ecto.Changeset

  schema "goal_posts" do
    field :content, :string

    field :post_type, Ecto.Enum,
      values: [:update, :milestone, :achievement, :challenge, :motivation],
      default: :update

    field :image_path, :string
    field :report_count, :integer, default: 0
    field :moderation_status, :string, default: "clean"

    belongs_to :goal, HeadsUp.Goal
    belongs_to :user, HeadsUp.Users
    belongs_to :step, HeadsUp.GoalStep

    has_many :goal_post_likes, HeadsUp.GoalPostLike, foreign_key: :goal_post_id
    has_many :reports, HeadsUp.Reports.Report, foreign_key: :post_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(goal_post, attrs) do
    goal_post
    |> cast(attrs, [:content, :post_type, :image_path, :goal_id, :user_id, :step_id, :report_count, :moderation_status])
    |> validate_required([:content, :post_type, :goal_id, :user_id])
    |> foreign_key_constraint(:goal_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:step_id)
  end
end
