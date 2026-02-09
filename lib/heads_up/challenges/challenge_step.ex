defmodule HeadsUp.Challenges.ChallengeStep do
  use Ecto.Schema
  import Ecto.Changeset

  @schedule_types [:daily, :twice_week, :every_other_day, :mon_fri, :custom_weekdays]
  @valid_weekdays ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]

  schema "challenge_steps" do
    field :title, :string
    field :description, :string
    field :order_index, :integer, default: 0
    field :schedule_type, Ecto.Enum, values: @schedule_types, default: :daily
    field :schedule_weekdays, {:array, :string}, default: []

    belongs_to :phase, HeadsUp.Challenges.ChallengePhase
    has_many :progress_records, HeadsUp.Challenges.ChallengeStepProgress, foreign_key: :step_id

    timestamps(type: :utc_datetime)
  end

  @required_fields [:title, :phase_id]
  @optional_fields [:description, :order_index, :schedule_type, :schedule_weekdays]

  def changeset(step, attrs) do
    step
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:title, min: 1, max: 255)
    |> validate_schedule_weekdays()
    |> foreign_key_constraint(:phase_id)
  end

  defp validate_schedule_weekdays(changeset) do
    schedule_type = get_field(changeset, :schedule_type)
    weekdays = get_field(changeset, :schedule_weekdays) || []

    cond do
      schedule_type == :custom_weekdays && weekdays == [] ->
        add_error(
          changeset,
          :schedule_weekdays,
          "must specify at least one weekday for custom schedule"
        )

      schedule_type == :custom_weekdays && !Enum.all?(weekdays, &(&1 in @valid_weekdays)) ->
        add_error(changeset, :schedule_weekdays, "contains invalid weekday values")

      true ->
        changeset
    end
  end

  @doc """
  Returns whether the step should be done on a given date.
  """
  def scheduled_for_date?(%__MODULE__{} = step, date) do
    day_of_week = Date.day_of_week(date)
    weekday = day_to_weekday(day_of_week)

    case step.schedule_type do
      :daily -> true
      :twice_week -> weekday in ["tuesday", "thursday"]
      :every_other_day -> rem(Date.diff(date, ~D[2020-01-01]), 2) == 0
      :mon_fri -> day_of_week in 1..5
      :custom_weekdays -> weekday in (step.schedule_weekdays || [])
    end
  end

  defp day_to_weekday(1), do: "monday"
  defp day_to_weekday(2), do: "tuesday"
  defp day_to_weekday(3), do: "wednesday"
  defp day_to_weekday(4), do: "thursday"
  defp day_to_weekday(5), do: "friday"
  defp day_to_weekday(6), do: "saturday"
  defp day_to_weekday(7), do: "sunday"
end
