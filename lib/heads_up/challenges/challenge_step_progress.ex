defmodule HeadsUp.Challenges.ChallengeStepProgress do
  use Ecto.Schema
  import Ecto.Changeset

  schema "challenge_step_progress" do
    field :completed_at, :utc_datetime
    field :status, Ecto.Enum, values: [:completed, :failed], default: :completed

    belongs_to :participant, HeadsUp.Challenges.ChallengeParticipant
    belongs_to :step, HeadsUp.Challenges.ChallengeStep

    timestamps(type: :utc_datetime)
  end

  @required_fields [:participant_id, :step_id]
  @optional_fields [:completed_at, :status]

  def changeset(progress, attrs) do
    progress
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> set_completed_at()
    |> unique_constraint([:participant_id, :step_id])
    |> foreign_key_constraint(:participant_id)
    |> foreign_key_constraint(:step_id)
  end

  defp set_completed_at(changeset) do
    if get_field(changeset, :completed_at) do
      changeset
    else
      put_change(changeset, :completed_at, DateTime.utc_now())
    end
  end
end
