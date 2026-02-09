defmodule HeadsUp.Challenges.DailyCheckIn do
  use Ecto.Schema
  import Ecto.Changeset

  schema "daily_check_ins" do
    field :day_number, :integer
    field :completed_date, :date
    field :total_tasks, :integer, default: 0
    field :completed_tasks, :integer, default: 0
    field :failed_tasks, :integer, default: 0
    field :skipped_tasks, :integer, default: 0
    field :note, :string
    field :mood, :string

    belongs_to :participant, HeadsUp.Challenges.ChallengeParticipant
    belongs_to :challenge, HeadsUp.Challenges.Challenge
    belongs_to :user, HeadsUp.Users

    has_many :check_in_likes, HeadsUp.Challenges.CheckInLike, foreign_key: :check_in_id
    has_many :check_in_comments, HeadsUp.Challenges.CheckInComment, foreign_key: :check_in_id

    timestamps(type: :utc_datetime)
  end

  @required_fields [:participant_id, :challenge_id, :user_id, :day_number, :completed_date]
  @optional_fields [:total_tasks, :completed_tasks, :failed_tasks, :skipped_tasks, :note, :mood]

  def changeset(check_in, attrs) do
    check_in
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:day_number, greater_than: 0)
    |> validate_number(:total_tasks, greater_than_or_equal_to: 0)
    |> validate_number(:completed_tasks, greater_than_or_equal_to: 0)
    |> validate_number(:failed_tasks, greater_than_or_equal_to: 0)
    |> validate_number(:skipped_tasks, greater_than_or_equal_to: 0)
    |> validate_inclusion(:mood, ["upset", "neutral", "good"],
      message: "must be upset, neutral, or good"
    )
    |> validate_task_counts()
    |> unique_constraint([:participant_id, :completed_date])
    |> foreign_key_constraint(:participant_id)
    |> foreign_key_constraint(:challenge_id)
    |> foreign_key_constraint(:user_id)
  end

  defp validate_task_counts(changeset) do
    total = get_field(changeset, :total_tasks) || 0
    completed = get_field(changeset, :completed_tasks) || 0
    failed = get_field(changeset, :failed_tasks) || 0
    skipped = get_field(changeset, :skipped_tasks) || 0

    if total > 0 && completed + failed + skipped != total do
      add_error(changeset, :total_tasks, "must equal sum of completed, failed, and skipped tasks")
    else
      changeset
    end
  end
end
