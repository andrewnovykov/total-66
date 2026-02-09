defmodule HeadsUp.Challenges.ChallengeTask do
  use Ecto.Schema
  import Ecto.Changeset

  @schedule_types [:daily, :twice_week, :every_other_day, :mon_fri, :custom_weekdays]
  @valid_weekdays ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]

  schema "challenge_tasks" do
    field :title, :string
    field :description, :string
    field :schedule_type, Ecto.Enum, values: @schedule_types, default: :daily
    field :schedule_weekdays, {:array, :string}, default: []
    field :task_type, Ecto.Enum, values: [:mandatory, :optional], default: :mandatory
    field :order_index, :integer, default: 0

    belongs_to :challenge, HeadsUp.Challenges.Challenge
    has_many :completions, HeadsUp.Challenges.ChallengeTaskCompletion, foreign_key: :task_id

    timestamps(type: :utc_datetime)
  end

  @required_fields [:title, :schedule_type, :challenge_id]
  @optional_fields [:description, :schedule_weekdays, :task_type, :order_index]

  def changeset(task, attrs) do
    task
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:title, min: 1, max: 255)
    |> validate_schedule_weekdays()
    |> foreign_key_constraint(:challenge_id)
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
  Returns whether the task should be done on a given date.
  """
  def scheduled_for_date?(%__MODULE__{} = task, date) do
    day_of_week = Date.day_of_week(date)
    weekday = day_to_weekday(day_of_week)

    case task.schedule_type do
      :daily -> true
      :twice_week -> weekday in ["tue", "thu"]
      :every_other_day -> rem(Date.diff(date, ~D[2020-01-01]), 2) == 0
      :mon_fri -> day_of_week in 1..5
      :custom_weekdays -> weekday in (task.schedule_weekdays || [])
    end
  end

  defp day_to_weekday(1), do: "mon"
  defp day_to_weekday(2), do: "tue"
  defp day_to_weekday(3), do: "wed"
  defp day_to_weekday(4), do: "thu"
  defp day_to_weekday(5), do: "fri"
  defp day_to_weekday(6), do: "sat"
  defp day_to_weekday(7), do: "sun"
end
