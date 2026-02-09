defmodule HeadsUp.Challenges.Challenge do
  use Ecto.Schema
  import Ecto.Changeset

  schema "challenges" do
    field :title, :string
    field :description, :string
    field :type, Ecto.Enum, values: [:predefined, :custom], default: :custom
    field :visibility, Ecto.Enum, values: [:public, :friends, :private], default: :public

    field :status, Ecto.Enum,
      values: [:active, :completed, :paused, :cancelled, :failed],
      default: :active

    field :image_path, :string
    # For custom challenges: specific dates
    field :start_date, :date
    field :end_date, :date
    # For predefined (official) challenges: duration in days
    field :duration_days, :integer
    # For community challenges shared as templates
    field :is_template, :boolean, default: false

    field :failure_reason, :string
    field :failed_at, :utc_datetime
    field :report_count, :integer, default: 0
    field :moderation_status, :string, default: "clean"

    belongs_to :creator, HeadsUp.Users, foreign_key: :creator_user_id
    belongs_to :category, HeadsUp.Challenges.ChallengeCategory, foreign_key: :category_id
    # For user challenges created from a template
    belongs_to :template, HeadsUp.Challenges.Challenge, foreign_key: :template_id

    has_many :phases, HeadsUp.Challenges.ChallengePhase
    has_many :tasks, HeadsUp.Challenges.ChallengeTask
    has_many :participants, HeadsUp.Challenges.ChallengeParticipant
    has_many :daily_check_ins, HeadsUp.Challenges.DailyCheckIn
    # Challenges created from this template (if is_template = true)
    has_many :derived_challenges, HeadsUp.Challenges.Challenge, foreign_key: :template_id

    timestamps(type: :utc_datetime)
  end

  @base_required [:title, :type, :creator_user_id, :category_id]
  @optional_fields [
    :description,
    :visibility,
    :status,
    :image_path,
    :start_date,
    :end_date,
    :duration_days,
    :is_template,
    :template_id,
    :failure_reason,
    :failed_at,
    :report_count,
    :moderation_status
  ]

  def changeset(challenge, attrs) do
    challenge
    |> cast(attrs, @base_required ++ @optional_fields)
    |> validate_required(@base_required, message: "is required")
    |> validate_length(:title, min: 3, max: 255)
    |> validate_by_type()
    |> foreign_key_constraint(:creator_user_id)
    |> foreign_key_constraint(:category_id)
  end

  defp validate_by_type(changeset) do
    is_template = get_field(changeset, :is_template)
    template_id = get_field(changeset, :template_id)

    cond do
      # All templates (official or community) only need duration_days
      is_template ->
        changeset
        |> validate_required([:duration_days], message: "is required")
        |> validate_number(:duration_days, greater_than: 0, message: "must be greater than 0")

      # Personal challenges (from template or user-created) need dates
      template_id != nil ->
        changeset
        |> validate_required([:start_date, :end_date], message: "is required")
        |> validate_dates()

      # Personal challenge created directly (no template) needs dates
      true ->
        changeset
        |> validate_required([:start_date, :end_date], message: "is required")
        |> validate_dates()
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
