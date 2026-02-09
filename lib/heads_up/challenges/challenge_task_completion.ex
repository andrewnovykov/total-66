defmodule HeadsUp.Challenges.ChallengeTaskCompletion do
  use Ecto.Schema
  import Ecto.Changeset

  schema "challenge_task_completions" do
    field :completed_date, :date
    field :completed_at, :utc_datetime
    field :status, Ecto.Enum, values: [:accomplished, :failed], default: :accomplished

    belongs_to :participant, HeadsUp.Challenges.ChallengeParticipant
    belongs_to :task, HeadsUp.Challenges.ChallengeTask

    timestamps(type: :utc_datetime)
  end

  @required_fields [:completed_date, :participant_id, :task_id]
  @optional_fields [:completed_at, :status]

  def changeset(completion, attrs) do
    completion
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> set_completed_at()
    |> unique_constraint([:participant_id, :task_id, :completed_date])
    |> foreign_key_constraint(:participant_id)
    |> foreign_key_constraint(:task_id)
  end

  defp set_completed_at(changeset) do
    if get_field(changeset, :completed_at) do
      changeset
    else
      put_change(changeset, :completed_at, DateTime.utc_now())
    end
  end
end
