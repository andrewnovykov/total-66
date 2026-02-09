defmodule HeadsUp.Challenges.CheckInComment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "check_in_comments" do
    field :content, :string

    belongs_to :daily_check_in, HeadsUp.Challenges.DailyCheckIn, foreign_key: :check_in_id
    belongs_to :user, HeadsUp.Users

    timestamps(type: :utc_datetime)
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:content, :check_in_id, :user_id])
    |> validate_required([:content, :check_in_id, :user_id])
    |> validate_length(:content, min: 1, max: 2000)
    |> foreign_key_constraint(:check_in_id)
    |> foreign_key_constraint(:user_id)
  end
end
