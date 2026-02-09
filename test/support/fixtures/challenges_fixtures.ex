defmodule HeadsUp.ChallengesFixtures do
  @moduledoc """
  Test fixtures for Challenges context.
  """

  alias HeadsUp.Challenges

  alias HeadsUp.Challenges.{
    Challenge,
    ChallengeCategory,
    ChallengePhase,
    ChallengeStep,
    ChallengeTask,
    ChallengeParticipant
  }

  alias HeadsUp.Repo

  def unique_challenge_title, do: "Challenge #{System.unique_integer([:positive])}"
  def unique_category_name, do: "Category #{System.unique_integer([:positive])}"

  def challenge_category_fixture(attrs \\ %{}) do
    {:ok, category} =
      attrs
      |> Enum.into(%{
        name: unique_category_name(),
        description: "Test category description",
        status: :active,
        order: 0
      })
      |> then(fn attrs ->
        %ChallengeCategory{}
        |> ChallengeCategory.changeset(attrs)
        |> Repo.insert()
      end)

    category
  end

  def challenge_fixture(attrs \\ %{}) do
    user = attrs[:user] || HeadsUp.AuthFixtures.user_fixture()
    category = attrs[:category] || challenge_category_fixture()
    type = attrs[:type] || :custom
    is_template = attrs[:is_template]

    defaults = %{
      title: unique_challenge_title(),
      description: "Test challenge description",
      type: type,
      visibility: :public,
      status: :active,
      creator_user_id: user.id,
      category_id: category.id
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
      |> Map.merge(Map.drop(attrs, [:user, :category]))

    {:ok, challenge} =
      %Challenge{}
      |> Challenge.changeset(final_attrs)
      |> Repo.insert()

    challenge
  end

  def predefined_challenge_fixture(attrs \\ %{}) do
    admin = attrs[:user] || HeadsUp.AuthFixtures.admin_fixture()
    category = attrs[:category] || challenge_category_fixture()

    defaults = %{
      title: unique_challenge_title(),
      description: "Test challenge description",
      type: :predefined,
      visibility: :public,
      status: :active,
      creator_user_id: admin.id,
      category_id: category.id,
      duration_days: attrs[:duration_days] || 30,
      # Official challenges are templates
      is_template: true
    }

    # Merge attrs over defaults, excluding user and category
    final_attrs = Map.merge(defaults, Map.drop(attrs, [:user, :category, :start_date, :end_date]))

    {:ok, challenge} =
      %Challenge{}
      |> Challenge.changeset(final_attrs)
      |> Repo.insert()

    challenge
  end

  def challenge_phase_fixture(attrs \\ %{}) do
    challenge = attrs[:challenge] || challenge_fixture()

    {:ok, phase} =
      attrs
      |> Enum.into(%{
        title: "Phase #{System.unique_integer([:positive])}",
        description: "Test phase description",
        order_index: 0,
        challenge_id: challenge.id
      })
      |> then(fn attrs ->
        %ChallengePhase{}
        |> ChallengePhase.changeset(attrs)
        |> Repo.insert()
      end)

    phase
  end

  def challenge_step_fixture(attrs \\ %{}) do
    phase = attrs[:phase] || challenge_phase_fixture()

    {:ok, step} =
      attrs
      |> Enum.into(%{
        title: "Step #{System.unique_integer([:positive])}",
        description: "Test step description",
        order_index: 0,
        phase_id: phase.id
      })
      |> then(fn attrs ->
        %ChallengeStep{}
        |> ChallengeStep.changeset(attrs)
        |> Repo.insert()
      end)

    step
  end

  def challenge_task_fixture(attrs \\ %{}) do
    challenge = attrs[:challenge] || challenge_fixture()

    {:ok, task} =
      attrs
      |> Enum.into(%{
        title: "Task #{System.unique_integer([:positive])}",
        description: "Test task description",
        schedule_type: :daily,
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
        :predefined ->
          start = attrs[:start_date] || Date.utc_today()
          {start, Date.add(start, challenge.duration_days || 30)}

        :custom ->
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
