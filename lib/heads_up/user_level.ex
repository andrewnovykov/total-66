defmodule HeadsUp.UserLevel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_levels" do
    field :level, :integer, default: 1
    field :xp, :integer, default: 0
    field :level_name, :string, default: "Seastar"

    belongs_to :user, HeadsUp.Users

    timestamps(type: :utc_datetime)
  end

  def changeset(user_level, attrs) do
    user_level
    |> cast(attrs, [:level, :xp, :level_name, :user_id])
    |> validate_required([:level, :xp, :level_name, :user_id])
    |> validate_number(:level, greater_than: 0, less_than_or_equal_to: 40)
    |> validate_number(:xp, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user_id)
  end
end
