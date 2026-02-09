defmodule HeadsUp.Challenges.CheckInLike do
  use Ecto.Schema
  import Ecto.Changeset

  schema "check_in_likes" do
    field :like_type, :string, default: "like"
    belongs_to :daily_check_in, HeadsUp.Challenges.DailyCheckIn, foreign_key: :check_in_id
    belongs_to :user, HeadsUp.Users

    timestamps(type: :utc_datetime)
  end

  def changeset(like, attrs) do
    like
    |> cast(attrs, [:check_in_id, :user_id, :like_type])
    |> validate_required([:check_in_id, :user_id])
    |> validate_inclusion(:like_type, ["like", "dislike"])
    |> foreign_key_constraint(:check_in_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:check_in_id, :user_id])
  end
end
