defmodule HeadsUp.Challenges.ChallengeParticipant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "challenge_participants" do
    field :status, Ecto.Enum,
      values: [:active, :completed, :dropped, :cancelled, :failed],
      default: :active

    field :joined_at, :utc_datetime
    field :completed_at, :utc_datetime
    # Participant's own schedule (calculated from challenge duration or set by user)
    field :start_date, :date
    field :end_date, :date

    field :failure_reason, :string
    field :failed_at, :utc_datetime

    belongs_to :challenge, HeadsUp.Challenges.Challenge
    belongs_to :user, HeadsUp.Users

    has_many :task_completions, HeadsUp.Challenges.ChallengeTaskCompletion,
      foreign_key: :participant_id

    has_many :daily_check_ins, HeadsUp.Challenges.DailyCheckIn, foreign_key: :participant_id

    timestamps(type: :utc_datetime)
  end

  @required_fields [:challenge_id, :user_id, :start_date, :end_date]
  @optional_fields [:status, :joined_at, :completed_at, :failure_reason, :failed_at]

  def changeset(participant, attrs) do
    participant
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> set_joined_at()
    |> validate_dates()
    |> unique_constraint([:challenge_id, :user_id])
    |> foreign_key_constraint(:challenge_id)
    |> foreign_key_constraint(:user_id)
  end

  defp set_joined_at(changeset) do
    if get_field(changeset, :joined_at) do
      changeset
    else
      put_change(changeset, :joined_at, DateTime.utc_now())
    end
  end

  defp validate_dates(changeset) do
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    if start_date && end_date && Date.compare(start_date, end_date) == :gt do
      add_error(changeset, :end_date, "must be after start date")
    else
      changeset
    end
  end
end
