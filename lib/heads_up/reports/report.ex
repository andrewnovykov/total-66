defmodule HeadsUp.Reports.Report do
  use Ecto.Schema
  import Ecto.Changeset

  @reasons ["spam", "offensive", "inappropriate", "harassment", "misinformation", "other"]

  schema "reports" do
    field :reason, :string
    field :description, :string

    belongs_to :user, HeadsUp.Users
    belongs_to :reported_user, HeadsUp.Users, foreign_key: :reported_user_id
    belongs_to :challenge, HeadsUp.Challenges.Challenge

    timestamps(type: :utc_datetime)
  end

  def reasons, do: @reasons

  @doc false
  def changeset(report, attrs) do
    report
    |> cast(attrs, [:reason, :description, :user_id, :reported_user_id, :challenge_id])
    |> validate_required([:reason, :user_id])
    |> validate_inclusion(:reason, @reasons)
    |> validate_length(:description, max: 500)
    |> validate_has_target()
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:reported_user_id)
    |> foreign_key_constraint(:challenge_id)
    |> unique_constraint([:reported_user_id, :user_id], name: :reports_reported_user_id_user_id_index)
    |> unique_constraint([:challenge_id, :user_id], name: :reports_challenge_id_user_id_index)
  end

  defp validate_has_target(changeset) do
    reported_user_id = get_field(changeset, :reported_user_id)
    challenge_id = get_field(changeset, :challenge_id)

    if is_nil(reported_user_id) and is_nil(challenge_id) do
      add_error(changeset, :base, "must report a user or challenge")
    else
      changeset
    end
  end
end
