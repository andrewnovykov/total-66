defmodule HeadsUp.Challenges.ChallengePhase do
  use Ecto.Schema
  import Ecto.Changeset

  schema "challenge_phases" do
    field :title, :string
    field :description, :string
    field :order_index, :integer, default: 0
    # For Community challenges: actual calendar dates
    field :start_date, :date
    field :end_date, :date
    # For Official (template) challenges: relative day numbers
    field :start_day, :integer
    field :end_day, :integer

    belongs_to :challenge, HeadsUp.Challenges.Challenge
    has_many :steps, HeadsUp.Challenges.ChallengeStep, foreign_key: :phase_id

    timestamps(type: :utc_datetime)
  end

  @required_fields [:title, :challenge_id]
  @optional_fields [:description, :order_index, :start_date, :end_date, :start_day, :end_day]

  def changeset(phase, attrs) do
    phase
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:title, min: 1, max: 255)
    |> validate_date_range()
    |> foreign_key_constraint(:challenge_id)
  end

  defp validate_date_range(changeset) do
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    if start_date && end_date && Date.compare(start_date, end_date) == :gt do
      add_error(changeset, :end_date, "must be after start date")
    else
      changeset
    end
  end
end
