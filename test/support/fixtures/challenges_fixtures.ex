defmodule HeadsUp.ChallengesFixtures do
  @moduledoc """
  Test fixtures for Challenges context.
  """

  alias HeadsUp.Challenges.{
    Challenge,
    ChallengeTask,
    ChallengeParticipant
  }

  alias HeadsUp.Repo

  def unique_challenge_title, do: "Challenge #{System.unique_integer([:positive])}"

  def challenge_fixture(attrs \\ %{}) do
    user = attrs[:user] || HeadsUp.AuthFixtures.user_fixture()
    type = attrs[:type] || :community
    is_template = attrs[:is_template]

    defaults = %{
      title: unique_challenge_title(),
      description: "Test challenge description",
      type: type,
      visibility: :public,
      status: :active,
      creator_user_id: user.id
    }

    # Add type-specific defaults
    # Templates (any type) use duration_days only
    # Personal challenges use start_date/end_date
    type_defaults =
      if is_template == true do
        %{duration_days: 30, is_template: true}
      else
        %{start_date: Date.utc_today(), end_date: Date.add(Date.utc_today(), 30)}
      end

    # Merge attrs over defaults (attrs win)
    final_attrs =
      defaults
      |> Map.merge(type_defaults)
      |> Map.merge(Map.drop(attrs, [:user]))

    {:ok, challenge} =
      %Challenge{}
      |> Challenge.changeset(final_attrs)
      |> Repo.insert()

    challenge
  end

  def official_challenge_fixture(attrs \\ %{}) do
    admin = attrs[:user] || HeadsUp.AuthFixtures.admin_fixture()

    defaults = %{
      title: unique_challenge_title(),
      description: "Test challenge description",
      type: :official,
      visibility: :public,
      status: :active,
      creator_user_id: admin.id,
      duration_days: attrs[:duration_days] || 30,
      # Official challenges are templates
      is_template: true
    }

    # Merge attrs over defaults, excluding user
    final_attrs = Map.merge(defaults, Map.drop(attrs, [:user, :start_date, :end_date]))

    {:ok, challenge} =
      %Challenge{}
      |> Challenge.changeset(final_attrs)
      |> Repo.insert()

    challenge
  end

  def challenge_task_fixture(attrs \\ %{}) do
    challenge = attrs[:challenge] || challenge_fixture()

    {:ok, task} =
      attrs
      |> Enum.into(%{
        title: "Task #{System.unique_integer([:positive])}",
        description: "Test task description",
        schedule_type: :daily,
        task_type: :mandatory,
        order_index: 0,
        challenge_id: challenge.id
      })
      |> then(fn attrs ->
        %ChallengeTask{}
        |> ChallengeTask.changeset(attrs)
        |> Repo.insert()
      end)

    task
  end

  def challenge_participant_fixture(attrs \\ %{}) do
    challenge = attrs[:challenge] || challenge_fixture()
    user = attrs[:user] || HeadsUp.AuthFixtures.user_fixture()

    # Calculate dates based on challenge type
    {start_date, end_date} =
      case challenge.type do
        :official ->
          start = attrs[:start_date] || Date.utc_today()
          {start, Date.add(start, challenge.duration_days || 30)}

        :community ->
          {challenge.start_date, challenge.end_date}
      end

    {:ok, participant} =
      attrs
      |> Enum.into(%{
        status: :active,
        joined_at: DateTime.utc_now(),
        challenge_id: challenge.id,
        user_id: user.id,
        start_date: start_date,
        end_date: end_date
      })
      |> then(fn attrs ->
        %ChallengeParticipant{}
        |> ChallengeParticipant.changeset(attrs)
        |> Repo.insert()
      end)

    participant
  end
end
