defmodule HeadsUp.GoalStep do
  use Ecto.Schema
  import Ecto.Changeset

  schema "goal_steps" do
    field :title, :string
    field :completed, :boolean, default: false
    field :order, :integer

    belongs_to :goal, HeadsUp.Goal

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(goal_step, attrs) do
    goal_step
    |> cast(attrs, [:title, :completed, :order, :goal_id])
    |> validate_required([:title, :order, :goal_id])
    |> validate_length(:title, min: 1, max: 255)
    |> foreign_key_constraint(:goal_id)
  end
end
