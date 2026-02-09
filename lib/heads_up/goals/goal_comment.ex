defmodule HeadsUp.Goals.GoalComment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "goal_comments" do
    field :content, :string

    belongs_to :goal_post, HeadsUp.Goals.GoalPost
    belongs_to :user, HeadsUp.Users

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:content, :goal_post_id, :user_id])
    |> validate_required([:content, :goal_post_id, :user_id])
    |> validate_length(:content, min: 1, max: 2000)
    |> foreign_key_constraint(:goal_post_id)
    |> foreign_key_constraint(:user_id)
  end
end
