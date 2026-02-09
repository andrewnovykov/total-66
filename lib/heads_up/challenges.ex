defmodule HeadsUp.Challenges do
  @moduledoc """
  The Challenges context manages challenge creation, participation, and progress tracking.

  Challenges come in two types:
  - Predefined: Admin-created with phases and steps
  - Custom: User-created with scheduled tasks
  """

  import Ecto.Query, warn: false
  alias HeadsUp.Repo
  alias HeadsUp.Accounts
  alias HeadsUp.ActivityService

  alias HeadsUp.Challenges.{
    Challenge,
    ChallengeCategory,
    ChallengePhase,
    ChallengeStep,
    ChallengeTask,
    ChallengeParticipant,
    ChallengeStepProgress,
    ChallengeTaskCompletion,
    CheckInComment,
    CheckInLike,
    DailyCheckIn
  }

  # ============================================================================
  # Challenge CRUD
  # ============================================================================

  @doc """
  Lists public challenge templates (for guests/main page).
  Only templates are shown on the main Challenges page.
  """
  def list_public_challenges do
    from(c in Challenge,
      where:
        c.visibility == :public and c.status == :active and c.is_template == true and
          c.moderation_status != "hidden",
      order_by: [desc: c.inserted_at]
    )
    |> Repo.all()
    |> Repo.preload([:creator, :category, :derived_challenges])
  end

  @doc """
  Lists challenge templates visible to a specific user.
  Only templates are shown on the main Challenges page.
  """
  def list_visible_challenges(user_id) do
    friend_ids = get_friend_ids(user_id)

    from(c in Challenge,
      where:
        c.is_template == true and
          c.status == :active and
          c.moderation_status != "hidden" and
          (c.visibility == :public or
             c.creator_user_id == ^user_id or
             (c.visibility == :friends and c.creator_user_id in ^friend_ids)),
      order_by: [desc: c.inserted_at]
    )
    |> Repo.all()
    |> Repo.preload([:creator, :category, :derived_challenges])
  end

  @doc """
  Lists predefined challenges (admin-created).
  """
  def list_predefined_challenges do
    from(c in Challenge,
      where:
        c.type == :predefined and c.visibility == :public and c.status == :active and
          c.moderation_status != "hidden",
      order_by: [desc: c.inserted_at]
    )
    |> Repo.all()
    |> Repo.preload([:creator, :category])
  end

  @doc """
  Lists challenges created by a specific user.
  """
  def list_user_challenges(user_id) do
    from(c in Challenge,
      where: c.creator_user_id == ^user_id,
      order_by: [desc: c.inserted_at]
    )
    |> Repo.all()
    |> Repo.preload([:category])
  end

  @doc """
  Lists challenges a user is participating in.
  """
  def list_participating_challenges(user_id) do
    from(c in Challenge,
      join: p in ChallengeParticipant,
      on: p.challenge_id == c.id,
      where: p.user_id == ^user_id and p.status == :active,
      order_by: [desc: p.joined_at]
    )
    |> Repo.all()
    |> Repo.preload([:creator, :category])
  end

  @doc """
  Gets a single challenge by ID.
  """
  def get_challenge(id) do
    Repo.get(Challenge, id)
  end

  @doc """
  Gets a challenge with all preloaded associations.
  """
  def get_challenge!(id) do
    Repo.get!(Challenge, id)
    |> Repo.preload([
      :creator,
      :category,
      participants: :user,
      phases: [steps: :progress_records],
      tasks: :completions
    ])
  end

  @doc """
  Gets a challenge with basic preloads for display.
  """
  def get_challenge_for_display(id) do
    case Repo.get(Challenge, id) do
      nil ->
        nil

      challenge ->
        challenge
        |> Repo.preload([
          :creator,
          :category,
          participants: :user,
          phases: [steps: []],
          tasks: []
        ])
    end
  end

  @doc """
  Creates a challenge.
  For predefined challenges, only admins can create.
  For custom challenges, any user can create.
  """
  def create_challenge(attrs, user) do
    type = Map.get(attrs, :type) || Map.get(attrs, "type") || :custom

    is_template = type in [:predefined, "predefined"] && user.role in [:admin, "admin"]

    cond do
      type in [:predefined, "predefined"] && user.role not in [:admin, "admin"] ->
        {:error, :unauthorized, "Only admins can create predefined challenges"}

      # Check active item limit for personal challenges (not templates)
      !is_template &&
          HeadsUp.BusinessRules.can_create_active_item?(user.id) ==
            {:error, :active_limit_reached} ->
        {:error, :active_limit_reached}

      true ->
        with {:ok, attrs} <- add_system_challenge_attrs(attrs, user.id, is_template) do
          result =
            %Challenge{}
            |> Challenge.changeset(attrs)
            |> Repo.insert()

          case result do
            {:ok, challenge} ->
              ActivityService.track_activity(user.id, "challenge_created",
                challenge_id: challenge.id,
                description: "Created challenge: #{challenge.title}"
              )

              {:ok, challenge}

            error ->
              error
          end
        else
          {:error, :mixed_keys} ->
            {:error, :invalid_attrs,
             "Challenge params must use either all atom keys or all string keys"}
        end
    end
  end

  defp add_system_challenge_attrs(attrs, creator_user_id, is_template) do
    case attrs_key_type(attrs) do
      :atom ->
        {:ok,
         attrs
         |> Map.put(:creator_user_id, creator_user_id)
         |> Map.put(:is_template, is_template)}

      :string ->
        {:ok,
         attrs
         |> Map.put("creator_user_id", creator_user_id)
         |> Map.put("is_template", is_template)}

      :mixed ->
        {:error, :mixed_keys}
    end
  end

  defp attrs_key_type(attrs) do
    has_atom_keys? = Enum.any?(Map.keys(attrs), &is_atom/1)
    has_string_keys? = Enum.any?(Map.keys(attrs), &is_binary/1)

    cond do
      has_atom_keys? && has_string_keys? -> :mixed
      has_string_keys? -> :string
      true -> :atom
    end
  end

  @doc """
  Updates a challenge with ownership validation.
  """
  def update_challenge(%Challenge{} = challenge, attrs, user_id) do
    if challenge.creator_user_id == user_id do
      challenge
      |> Challenge.changeset(attrs)
      |> Repo.update()
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Deletes a challenge with ownership validation.
  Creator can delete their own challenge. Admin can delete any challenge.
  """
  def delete_challenge(%Challenge{} = challenge, user_id) do
    user = Accounts.get_user(user_id)
    is_owner = challenge.creator_user_id == user_id
    is_admin = user.role in [:admin, "admin"]

    if is_owner || is_admin do
      Repo.delete(challenge)
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking challenge changes.
  """
  def change_challenge(%Challenge{} = challenge, attrs \\ %{}) do
    Challenge.changeset(challenge, attrs)
  end

  @doc """
  Creates a user's challenge from a template.
  Copies the template structure and creates a personal challenge with user's dates.
  """
  def start_challenge_from_template(template_id, user_id, start_date \\ Date.utc_today()) do
    # Check active item limit before starting
    case HeadsUp.BusinessRules.can_create_active_item?(user_id) do
      {:error, :active_limit_reached} ->
        {:error, :active_limit_reached}

      :ok ->
        do_start_challenge_from_template(template_id, user_id, start_date)
    end
  end

  defp do_start_challenge_from_template(template_id, user_id, start_date) do
    template = get_challenge!(template_id) |> Repo.preload([:phases, :tasks, phases: :steps])

    unless template.is_template do
      {:error, :not_a_template}
    else
      # Calculate end date from template's duration_days
      duration = template.duration_days || 30
      end_date = Date.add(start_date, duration)

      # Create the user's challenge
      challenge_attrs = %{
        title: template.title,
        description: template.description,
        type: template.type,
        # User challenges are private by default
        visibility: :private,
        status: :active,
        creator_user_id: user_id,
        category_id: template.category_id,
        template_id: template.id,
        start_date: start_date,
        end_date: end_date,
        is_template: false
      }

      result =
        %Challenge{}
        |> Challenge.changeset(challenge_attrs)
        |> Repo.insert()

      case result do
        {:ok, challenge} ->
          # Copy phases and steps for predefined templates
          if template.type == :predefined do
            copy_phases_and_steps(template, challenge)
          else
            # Copy tasks for custom templates
            copy_tasks(template, challenge)
          end

          # Automatically add the user as a participant
          join_challenge(challenge.id, user_id, start_date: start_date)

          ActivityService.track_activity(user_id, "challenge_started",
            challenge_id: challenge.id,
            template_id: template.id,
            description: "Started challenge: #{challenge.title}"
          )

          {:ok, Repo.preload(challenge, [:phases, :tasks, phases: :steps])}

        error ->
          error
      end
    end
  end

  defp copy_phases_and_steps(template, challenge) do
    for phase <- template.phases do
      {:ok, new_phase} =
        create_phase(
          %{
            title: phase.title,
            description: phase.description,
            order_index: phase.order_index,
            start_day: phase.start_day,
            end_day: phase.end_day,
            challenge_id: challenge.id
          },
          challenge.creator_user_id
        )

      for step <- phase.steps || [] do
        create_step(
          %{
            title: step.title,
            description: step.description,
            order_index: step.order_index,
            schedule_type: step.schedule_type,
            schedule_weekdays: step.schedule_weekdays,
            phase_id: new_phase.id
          },
          challenge.creator_user_id
        )
      end
    end
  end

  defp copy_tasks(template, challenge) do
    for task <- template.tasks do
      create_task(
        %{
          title: task.title,
          description: task.description,
          schedule_type: task.schedule_type,
          schedule_weekdays: task.schedule_weekdays,
          challenge_id: challenge.id
        },
        challenge.creator_user_id
      )
    end
  end

  @doc """
  Shares a user's challenge as a community template.
  Creates a copy marked as is_template = true.
  """
  def share_as_template(challenge_id, user_id) do
    challenge = get_challenge!(challenge_id) |> Repo.preload([:phases, :tasks, phases: :steps])

    unless challenge.creator_user_id == user_id do
      {:error, :unauthorized}
    else
      if challenge.is_template do
        {:error, :already_template}
      else
        # Create the template — templates only have duration_days, no dates
        duration =
          if challenge.start_date && challenge.end_date do
            Date.diff(challenge.end_date, challenge.start_date)
          else
            challenge.duration_days || 30
          end

        template_attrs = %{
          title: challenge.title,
          description: challenge.description,
          type: :custom,
          visibility: :public,
          status: :active,
          creator_user_id: user_id,
          category_id: challenge.category_id,
          duration_days: duration,
          is_template: true
        }

        result =
          %Challenge{}
          |> Challenge.changeset(template_attrs)
          |> Repo.insert()

        case result do
          {:ok, template} ->
            # Link original challenge back to the new template
            challenge
            |> Challenge.changeset(%{template_id: template.id})
            |> Repo.update()

            # Copy tasks
            copy_tasks(challenge, template)

            ActivityService.track_activity(user_id, "challenge_shared",
              challenge_id: challenge.id,
              template_id: template.id,
              description: "Shared challenge as template: #{template.title}"
            )

            {:ok, template}

          error ->
            error
        end
      end
    end
  end

  @doc """
  Lists user's own challenges (not templates).
  """
  def list_my_challenges(user_id) do
    from(c in Challenge,
      where: c.creator_user_id == ^user_id and c.is_template == false,
      order_by: [desc: c.inserted_at]
    )
    |> Repo.all()
    |> Repo.preload([:creator, :category, :template, participants: :user])
  end

  @doc """
  Finds a user's challenge that was created from a specific template.
  Returns the challenge or nil.
  """
  def get_user_challenge_from_template(template_id, user_id) do
    from(c in Challenge,
      where:
        c.template_id == ^template_id and c.creator_user_id == ^user_id and c.is_template == false,
      order_by: [desc: c.inserted_at],
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Gets users who started challenges from a template.
  Returns list of %{user: user, challenge_id: id, started_at: date}.
  """
  def get_template_starters(template_id) do
    from(c in Challenge,
      where: c.template_id == ^template_id and c.is_template == false,
      join: u in assoc(c, :creator),
      select: %{user: u, challenge_id: c.id, started_at: c.start_date, status: c.status},
      order_by: [desc: c.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Groups template starters by their challenge status.
  Returns a map with :active, :completed, and :failed lists.
  """
  def group_starters_by_status(starters) do
    %{
      active: Enum.filter(starters, &(&1.status == :active)),
      completed: Enum.filter(starters, &(&1.status == :completed)),
      failed: Enum.filter(starters, &(&1.status in [:failed, :cancelled]))
    }
  end

  @doc """
  Computes success rate statistics from grouped starters.
  """
  def template_success_rate(grouped) do
    completed = length(grouped.completed)
    failed = length(grouped.failed)
    active = length(grouped.active)
    total = completed + failed + active
    finished = completed + failed
    success_rate = if finished > 0, do: Float.round(completed / finished * 100, 1), else: 0.0

    %{
      total: total,
      completed: completed,
      failed: failed,
      active: active,
      success_rate: success_rate
    }
  end

  @doc """
  Lists available templates (official and community).
  """
  def list_templates do
    from(c in Challenge,
      where:
        c.is_template == true and c.visibility == :public and c.status == :active and
          c.moderation_status != "hidden",
      order_by: [desc: c.inserted_at]
    )
    |> Repo.all()
    |> Repo.preload([:creator, :category])
  end

  # ============================================================================
  # Challenge Categories (Admin Only)
  # ============================================================================

  @doc """
  Lists all challenge categories.
  """
  def list_categories do
    from(c in ChallengeCategory,
      order_by: [asc: c.order, asc: c.name]
    )
    |> Repo.all()
  end

  @doc """
  Lists active challenge categories.
  """
  def list_active_categories do
    from(c in ChallengeCategory,
      where: c.status == :active,
      order_by: [asc: c.order, asc: c.name]
    )
    |> Repo.all()
  end

  @doc """
  Gets a challenge category by ID.
  """
  def get_category(id), do: Repo.get(ChallengeCategory, id)

  @doc """
  Gets a challenge category by ID, raises if not found.
  """
  def get_category!(id), do: Repo.get!(ChallengeCategory, id)

  @doc """
  Creates a challenge category. Admin only.
  """
  def create_category(attrs, user) do
    if user.role in [:admin, "admin"] do
      %ChallengeCategory{}
      |> ChallengeCategory.changeset(attrs)
      |> Repo.insert()
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Updates a challenge category. Admin only.
  """
  def update_category(%ChallengeCategory{} = category, attrs, user) do
    if user.role in [:admin, "admin"] do
      category
      |> ChallengeCategory.changeset(attrs)
      |> Repo.update()
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Deletes a challenge category. Admin only.
  """
  def delete_category(%ChallengeCategory{} = category, user) do
    if user.role in [:admin, "admin"] do
      Repo.delete(category)
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking category changes.
  """
  def change_category(%ChallengeCategory{} = category, attrs \\ %{}) do
    ChallengeCategory.changeset(category, attrs)
  end

  # ============================================================================
  # Challenge Phases (for Predefined Challenges)
  # ============================================================================

  @doc """
  Creates a challenge phase.
  """
  def create_phase(attrs, user_id) do
    challenge_id = Map.get(attrs, :challenge_id) || Map.get(attrs, "challenge_id")
    challenge = get_challenge!(challenge_id)

    if challenge.creator_user_id == user_id do
      %ChallengePhase{}
      |> ChallengePhase.changeset(attrs)
      |> Repo.insert()
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Updates a challenge phase.
  """
  def update_phase(%ChallengePhase{} = phase, attrs, user_id) do
    phase = Repo.preload(phase, :challenge)

    if phase.challenge.creator_user_id == user_id do
      phase
      |> ChallengePhase.changeset(attrs)
      |> Repo.update()
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Deletes a challenge phase.
  """
  def delete_phase(%ChallengePhase{} = phase, user_id) do
    phase = Repo.preload(phase, :challenge)

    if phase.challenge.creator_user_id == user_id do
      Repo.delete(phase)
    else
      {:error, :unauthorized}
    end
  end

  # ============================================================================
  # Challenge Steps (within Phases)
  # ============================================================================

  @doc """
  Creates a challenge step within a phase.
  """
  def create_step(attrs, user_id) do
    phase_id = Map.get(attrs, :phase_id) || Map.get(attrs, "phase_id")
    phase = Repo.get!(ChallengePhase, phase_id) |> Repo.preload(:challenge)

    if phase.challenge.creator_user_id == user_id do
      %ChallengeStep{}
      |> ChallengeStep.changeset(attrs)
      |> Repo.insert()
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Updates a challenge step.
  """
  def update_step(%ChallengeStep{} = step, attrs, user_id) do
    step = Repo.preload(step, phase: :challenge)

    if step.phase.challenge.creator_user_id == user_id do
      step
      |> ChallengeStep.changeset(attrs)
      |> Repo.update()
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Deletes a challenge step.
  """
  def delete_step(%ChallengeStep{} = step, user_id) do
    step = Repo.preload(step, phase: :challenge)

    if step.phase.challenge.creator_user_id == user_id do
      Repo.delete(step)
    else
      {:error, :unauthorized}
    end
  end

  # ============================================================================
  # Challenge Tasks (for Custom Challenges)
  # ============================================================================

  @doc """
  Creates a challenge task.
  """
  def create_task(attrs, user_id) do
    challenge_id = Map.get(attrs, :challenge_id) || Map.get(attrs, "challenge_id")
    challenge = get_challenge!(challenge_id)

    if challenge.creator_user_id == user_id do
      %ChallengeTask{}
      |> ChallengeTask.changeset(attrs)
      |> Repo.insert()
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Updates a challenge task.
  """
  def update_task(%ChallengeTask{} = task, attrs, user_id) do
    task = Repo.preload(task, :challenge)

    if task.challenge.creator_user_id == user_id do
      task
      |> ChallengeTask.changeset(attrs)
      |> Repo.update()
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Deletes a challenge task.
  """
  def delete_task(%ChallengeTask{} = task, user_id) do
    task = Repo.preload(task, :challenge)

    if task.challenge.creator_user_id == user_id do
      Repo.delete(task)
    else
      {:error, :unauthorized}
    end
  end

  # ============================================================================
  # Challenge Participation
  # ============================================================================

  @doc """
  Joins a challenge. Any user can join unlimited challenges.
  Checks visibility and duplicate enrollment only.

  For predefined (official) challenges: user provides start_date, end_date is calculated from duration.
  For custom challenges: uses the challenge's start_date and end_date.
  """
  def join_challenge(challenge_id, user_id, opts \\ []) do
    challenge = get_challenge!(challenge_id)
    start_date = Keyword.get(opts, :start_date, Date.utc_today())

    cond do
      already_participating?(challenge_id, user_id) ->
        {:error, :already_joined}

      !can_view_challenge?(challenge, user_id) ->
        {:error, :access_denied}

      true ->
        # Calculate participant's dates based on challenge type
        {participant_start, participant_end} = calculate_participant_dates(challenge, start_date)

        result =
          %ChallengeParticipant{}
          |> ChallengeParticipant.changeset(%{
            challenge_id: challenge_id,
            user_id: user_id,
            status: :active,
            joined_at: DateTime.utc_now(),
            start_date: participant_start,
            end_date: participant_end
          })
          |> Repo.insert()

        case result do
          {:ok, participant} ->
            ActivityService.track_activity(user_id, "challenge_joined",
              challenge_id: challenge_id,
              description: "Joined challenge: #{challenge.title}"
            )

            {:ok, participant}

          error ->
            error
        end
    end
  end

  defp calculate_participant_dates(challenge, start_date) do
    cond do
      # Personal challenge with explicit dates — use them directly
      challenge.start_date && challenge.end_date ->
        {challenge.start_date, challenge.end_date}

      # Predefined template — calculate from duration
      challenge.type == :predefined ->
        end_date = Date.add(start_date, challenge.duration_days || 30)
        {start_date, end_date}

      # Fallback
      true ->
        {start_date, Date.add(start_date, 30)}
    end
  end

  @doc """
  Leaves/drops a challenge.
  """
  def leave_challenge(challenge_id, user_id) do
    case get_participant(challenge_id, user_id) do
      nil ->
        {:error, :not_found}

      participant ->
        participant
        |> ChallengeParticipant.changeset(%{status: :dropped})
        |> Repo.update()
    end
  end

  @doc """
  Gets a participant record for a user in a challenge.
  """
  def get_participant(challenge_id, user_id) do
    Repo.get_by(ChallengeParticipant, challenge_id: challenge_id, user_id: user_id)
  end

  @doc """
  Gets participant count for a challenge.
  """
  def get_participant_count(challenge_id) do
    from(p in ChallengeParticipant,
      where: p.challenge_id == ^challenge_id and p.status == :active
    )
    |> Repo.aggregate(:count)
  end

  @doc """
  Gets list of challenge IDs that a user has joined (active participation).
  """
  def get_user_joined_challenge_ids(user_id) do
    from(p in ChallengeParticipant,
      where: p.user_id == ^user_id and p.status == :active,
      select: p.challenge_id
    )
    |> Repo.all()
  end

  # ============================================================================
  # Progress Tracking
  # ============================================================================

  @doc """
  Marks a step as completed in a predefined challenge.
  """
  def complete_step(participant_id, step_id) do
    participant = Repo.get!(ChallengeParticipant, participant_id)

    result =
      %ChallengeStepProgress{}
      |> ChallengeStepProgress.changeset(%{
        participant_id: participant_id,
        step_id: step_id,
        completed_at: DateTime.utc_now()
      })
      |> Repo.insert()

    case result do
      {:ok, progress} ->
        check_and_complete_challenge(participant)
        {:ok, progress}

      error ->
        error
    end
  end

  @doc """
  Marks a task as completed (accomplished) for a specific date.
  """
  def complete_task(participant_id, task_id, date \\ Date.utc_today()) do
    record_task_status(participant_id, task_id, date, :accomplished)
  end

  @doc """
  Marks a task as failed for a specific date.
  """
  def fail_task(participant_id, task_id, date \\ Date.utc_today()) do
    record_task_status(participant_id, task_id, date, :failed)
  end

  defp record_task_status(participant_id, task_id, date, status) do
    participant = Repo.get!(ChallengeParticipant, participant_id) |> Repo.preload(:challenge)

    # First check if there's an existing record for this task/date
    existing =
      Repo.get_by(ChallengeTaskCompletion,
        participant_id: participant_id,
        task_id: task_id,
        completed_date: date
      )

    result =
      if existing do
        # Update existing record's status
        existing
        |> ChallengeTaskCompletion.changeset(%{status: status})
        |> Repo.update()
      else
        # Create new record
        %ChallengeTaskCompletion{}
        |> ChallengeTaskCompletion.changeset(%{
          participant_id: participant_id,
          task_id: task_id,
          completed_date: date,
          completed_at: DateTime.utc_now(),
          status: status
        })
        |> Repo.insert()
      end

    case result do
      {:ok, completion} ->
        activity_type =
          if status == :accomplished, do: "daily_task_completed", else: "daily_task_failed"

        ActivityService.track_activity(participant.user_id, activity_type,
          challenge_id: participant.challenge_id,
          description:
            if(status == :accomplished, do: "Completed daily task", else: "Failed daily task")
        )

        {:ok, completion}

      error ->
        error
    end
  end

  @doc """
  Uncompletes a step (removes progress).
  """
  def uncomplete_step(participant_id, step_id) do
    case Repo.get_by(ChallengeStepProgress, participant_id: participant_id, step_id: step_id) do
      nil -> {:error, :not_found}
      progress -> Repo.delete(progress)
    end
  end

  @doc """
  Uncompletes a task for a specific date.
  """
  def uncomplete_task(participant_id, task_id, date) do
    case Repo.get_by(ChallengeTaskCompletion,
           participant_id: participant_id,
           task_id: task_id,
           completed_date: date
         ) do
      nil -> {:error, :not_found}
      completion -> Repo.delete(completion)
    end
  end

  @doc """
  Checks if a step is completed by a participant.
  Only returns true for status :completed, not :failed.
  """
  def step_completed?(participant_id, step_id) do
    Repo.exists?(
      from(p in ChallengeStepProgress,
        where:
          p.participant_id == ^participant_id and p.step_id == ^step_id and p.status == :completed
      )
    )
  end

  @doc """
  Marks a step as failed for a participant.
  Upserts a ChallengeStepProgress record with status :failed.
  """
  def fail_step(participant_id, step_id) do
    existing =
      Repo.get_by(ChallengeStepProgress,
        participant_id: participant_id,
        step_id: step_id
      )

    result =
      if existing do
        existing
        |> ChallengeStepProgress.changeset(%{status: :failed, completed_at: DateTime.utc_now()})
        |> Repo.update()
      else
        %ChallengeStepProgress{}
        |> ChallengeStepProgress.changeset(%{
          participant_id: participant_id,
          step_id: step_id,
          status: :failed,
          completed_at: DateTime.utc_now()
        })
        |> Repo.insert()
      end

    case result do
      {:ok, progress} ->
        participant = Repo.get!(ChallengeParticipant, participant_id)

        ActivityService.track_activity(participant.user_id, "step_failed",
          challenge_id: participant.challenge_id,
          description: "Failed a challenge step"
        )

        {:ok, progress}

      error ->
        error
    end
  end

  @doc """
  Gets the status of a step for a participant.
  Returns :completed, :failed, or :pending.
  """
  def get_step_status(participant_id, step_id) do
    case Repo.get_by(ChallengeStepProgress,
           participant_id: participant_id,
           step_id: step_id
         ) do
      nil -> :pending
      %{status: status} -> status
    end
  end

  @doc """
  Checks if a task is completed for a specific date.
  """
  def task_completed?(participant_id, task_id, date) do
    Repo.exists?(
      from(c in ChallengeTaskCompletion,
        where:
          c.participant_id == ^participant_id and
            c.task_id == ^task_id and
            c.completed_date == ^date
      )
    )
  end

  @doc """
  Gets the status of a task for a specific date.
  Returns :accomplished, :failed, or :pending
  """
  def get_task_status(participant_id, task_id, date) do
    case Repo.get_by(ChallengeTaskCompletion,
           participant_id: participant_id,
           task_id: task_id,
           completed_date: date
         ) do
      nil -> :pending
      %{status: status} -> status
    end
  end

  @doc """
  Gets progress statistics for a participant.
  Returns daily progress (tasks today) and overall challenge progress (days elapsed).
  """
  def get_participant_progress(participant_id) do
    participant =
      Repo.get!(ChallengeParticipant, participant_id)
      |> Repo.preload(challenge: [:phases, :tasks])

    today = Date.utc_today()
    start_date = participant.start_date
    end_date = participant.end_date

    # Calculate overall challenge progress based on days
    total_days =
      if start_date && end_date do
        Date.diff(end_date, start_date)
      else
        1
      end

    days_elapsed =
      if start_date do
        max(0, Date.diff(today, start_date) + 1)
      else
        0
      end

    days_percentage = min(100, calculate_percentage(days_elapsed, total_days))

    {today_completed, today_failed, total_items} =
      case participant.challenge.type do
        :predefined ->
          # Predefined challenges: track step completions
          total = count_total_steps(participant.challenge)
          completed = count_completed_steps(participant_id)
          failed = count_failed_steps(participant_id)
          {completed, failed, total}

        :custom ->
          # Custom challenges: track task completions
          total = length(get_today_tasks(participant.challenge_id))
          completed = count_tasks_completed_today(participant_id)
          failed = count_tasks_failed_today(participant_id)
          {completed, failed, total}
      end

    %{
      type: participant.challenge.type,
      # Daily progress
      today_total: total_items,
      today_completed: today_completed,
      today_failed: today_failed,
      # Challenge progress (by days)
      total_days: total_days,
      days_elapsed: min(days_elapsed, total_days),
      days_percentage: days_percentage,
      start_date: start_date,
      end_date: end_date
    }
  end

  # ============================================================================
  # Challenge Failure
  # ============================================================================

  @doc """
  Fails a personal challenge. Only challenge owner can fail their challenge.
  Sets both challenge and participant status to :failed.
  """
  def fail_challenge(challenge_id, user_id, failure_reason \\ nil) do
    challenge = get_challenge!(challenge_id)
    participant = get_participant(challenge_id, user_id)

    cond do
      challenge.creator_user_id != user_id ->
        {:error, :unauthorized}

      challenge.is_template ->
        {:error, :cannot_fail_template}

      challenge.status == :failed ->
        {:error, :already_failed}

      is_nil(participant) ->
        {:error, :not_participating}

      true ->
        now = DateTime.utc_now()

        Ecto.Multi.new()
        |> Ecto.Multi.update(
          :challenge,
          Challenge.changeset(challenge, %{
            status: :failed,
            failure_reason: failure_reason,
            failed_at: now
          })
        )
        |> Ecto.Multi.update(
          :participant,
          ChallengeParticipant.changeset(participant, %{
            status: :failed,
            failure_reason: failure_reason,
            failed_at: now
          })
        )
        |> Repo.transaction()
        |> case do
          {:ok, %{challenge: challenge, participant: _participant}} ->
            ActivityService.track_activity(user_id, "challenge_failed",
              challenge_id: challenge_id,
              description: "Failed challenge: #{challenge.title}"
            )

            {:ok, challenge}

          {:error, _operation, changeset, _changes} ->
            {:error, changeset}
        end
    end
  end

  @doc """
  Cancels a personal challenge. Only the challenge owner can cancel.
  Challenge must be in :active status.
  """
  def cancel_challenge(challenge_id, user_id) do
    challenge = get_challenge!(challenge_id)
    participant = get_participant(challenge_id, user_id)

    cond do
      challenge.creator_user_id != user_id ->
        {:error, :unauthorized}

      challenge.is_template ->
        {:error, :cannot_cancel_template}

      challenge.status != :active ->
        {:error, :invalid_status}

      is_nil(participant) ->
        {:error, :not_participating}

      true ->
        Ecto.Multi.new()
        |> Ecto.Multi.update(
          :challenge,
          Challenge.changeset(challenge, %{status: :cancelled})
        )
        |> Ecto.Multi.update(
          :participant,
          ChallengeParticipant.changeset(participant, %{status: :cancelled})
        )
        |> Repo.transaction()
        |> case do
          {:ok, %{challenge: challenge}} ->
            ActivityService.track_activity(user_id, "challenge_cancelled",
              challenge_id: challenge_id,
              description: "Cancelled challenge: #{challenge.title}"
            )

            {:ok, challenge}

          {:error, _operation, changeset, _changes} ->
            {:error, changeset}
        end
    end
  end

  # ============================================================================
  # Daily Check-ins
  # ============================================================================

  @doc """
  Gets today's scheduled tasks for a challenge.
  Returns list of tasks that should be completed today based on schedule.
  """
  def get_today_tasks(challenge_id) do
    challenge = Repo.get!(Challenge, challenge_id) |> Repo.preload(:tasks)
    today = Date.utc_today()

    Enum.filter(challenge.tasks, fn task ->
      ChallengeTask.scheduled_for_date?(task, today)
    end)
  end

  @doc """
  Gets today's actionable items for a challenge.
  For predefined: returns all incomplete steps (steps are the daily items).
  For custom: returns today's scheduled tasks.
  """
  def get_today_items(challenge_id, participant_id) do
    challenge = Repo.get!(Challenge, challenge_id) |> Repo.preload([:tasks, phases: :steps])

    case challenge.type do
      :predefined ->
        # Return all steps, marking which are completed
        steps =
          challenge.phases
          |> Enum.sort_by(& &1.order_index)
          |> Enum.flat_map(fn phase ->
            phase.steps
            |> Enum.sort_by(& &1.order_index)
            |> Enum.map(fn step ->
              %{
                id: step.id,
                title: step.title,
                description: step.description,
                type: :step,
                status: get_step_status(participant_id, step.id)
              }
            end)
          end)

        {:steps, steps}

      :custom ->
        today = Date.utc_today()

        tasks =
          challenge.tasks
          |> Enum.filter(&ChallengeTask.scheduled_for_date?(&1, today))
          |> Enum.map(fn task ->
            status = get_task_status(participant_id, task.id, today)

            %{
              id: task.id,
              title: task.title,
              description: task.description,
              type: :task,
              schedule_type: task.schedule_type,
              status: status
            }
          end)

        {:tasks, tasks}
    end
  end

  @doc """
  Checks if a daily check-in has been submitted for today.
  """
  def has_checked_in_today?(participant_id) do
    has_checked_in_for_date?(participant_id, Date.utc_today())
  end

  @doc """
  Checks if a daily check-in has been submitted for a specific date.
  """
  def has_checked_in_for_date?(participant_id, date) do
    Repo.exists?(
      from(d in DailyCheckIn,
        where: d.participant_id == ^participant_id and d.completed_date == ^date
      )
    )
  end

  @doc """
  Gets dates that are missing check-ins for a participant.
  Returns a list of dates from start_date to min(today, end_date) that don't have check-ins.
  """
  def get_missed_check_in_days(participant_id) do
    participant = Repo.get!(ChallengeParticipant, participant_id)
    today = Date.utc_today()

    last_date =
      if participant.end_date && Date.compare(participant.end_date, today) == :lt do
        participant.end_date
      else
        today
      end

    # Don't count future dates or days before challenge started
    if Date.compare(participant.start_date, last_date) == :gt do
      []
    else
      checked_dates =
        from(d in DailyCheckIn,
          where: d.participant_id == ^participant_id,
          select: d.completed_date
        )
        |> Repo.all()
        |> MapSet.new()

      Date.range(participant.start_date, last_date)
      |> Enum.reject(&MapSet.member?(checked_dates, &1))
    end
  end

  @doc """
  Counts the maximum consecutive missed days for a participant.
  Used to determine if auto-fail threshold (7 days) is reached.
  """
  def max_consecutive_missed_days(participant_id) do
    missed = get_missed_check_in_days(participant_id)
    calculate_max_consecutive(missed)
  end

  defp calculate_max_consecutive([]), do: 0

  defp calculate_max_consecutive(dates) do
    dates
    |> Enum.sort(Date)
    |> Enum.reduce({1, 1, nil}, fn date, {current_streak, max_streak, prev_date} ->
      if prev_date && Date.diff(date, prev_date) == 1 do
        new_streak = current_streak + 1
        {new_streak, max(max_streak, new_streak), date}
      else
        {1, max(max_streak, 1), date}
      end
    end)
    |> elem(1)
  end

  @doc """
  Checks if a participant should be auto-failed (7+ consecutive missed days).
  If so, fails the challenge automatically. Called on page load and before check-in.
  Returns {:ok, :auto_failed} or {:ok, :active} or {:ok, other_status}.
  """
  def check_and_auto_fail(participant_id) do
    participant = Repo.get!(ChallengeParticipant, participant_id) |> Repo.preload(:challenge)

    if participant.status != :active do
      {:ok, participant.status}
    else
      consecutive = max_consecutive_missed_days(participant_id)

      if consecutive >= 7 do
        fail_challenge(
          participant.challenge_id,
          participant.user_id,
          "Auto-failed: #{consecutive} consecutive days without check-in"
        )

        {:ok, :auto_failed}
      else
        {:ok, :active}
      end
    end
  end

  @doc """
  Checks if all days of the challenge have been checked in.
  If so, auto-completes the challenge. Called after each check-in.
  Returns {:ok, :auto_completed} or {:ok, :active}.
  """
  def check_and_auto_complete(participant_id) do
    participant = Repo.get!(ChallengeParticipant, participant_id) |> Repo.preload(:challenge)

    if participant.status != :active do
      {:ok, participant.status}
    else
      total_days = Date.diff(participant.end_date, participant.start_date)

      check_in_count =
        from(d in DailyCheckIn,
          where: d.participant_id == ^participant_id
        )
        |> Repo.aggregate(:count)

      if check_in_count >= total_days and total_days > 0 do
        now = DateTime.utc_now()

        Ecto.Multi.new()
        |> Ecto.Multi.update(
          :challenge,
          Challenge.changeset(participant.challenge, %{status: :completed})
        )
        |> Ecto.Multi.update(
          :participant,
          ChallengeParticipant.changeset(participant, %{
            status: :completed,
            completed_at: now
          })
        )
        |> Repo.transaction()
        |> case do
          {:ok, %{challenge: _challenge}} ->
            ActivityService.track_activity(participant.user_id, "challenge_completed",
              challenge_id: participant.challenge_id,
              description: "Completed the challenge! All days checked in."
            )

            {:ok, :auto_completed}

          {:error, _operation, _changeset, _changes} ->
            {:ok, :active}
        end
      else
        {:ok, :active}
      end
    end
  end

  @doc """
  Creates a daily check-in for a participant.
  Accepts an optional check_in_date for backfilling missed days.
  Summarizes task completion status and creates a feed entry.
  After check-in, checks for auto-complete.
  """
  def create_daily_check_in(participant_id, attrs \\ %{}) do
    participant =
      Repo.get!(ChallengeParticipant, participant_id)
      |> Repo.preload(:challenge)

    # Allow checking in for a specific date (backfill) or default to today
    check_in_date =
      case Map.get(attrs, :check_in_date) || Map.get(attrs, "check_in_date") do
        nil ->
          Date.utc_today()

        %Date{} = d ->
          d

        date_str when is_binary(date_str) ->
          case Date.from_iso8601(date_str) do
            {:ok, d} -> d
            _ -> Date.utc_today()
          end
      end

    cond do
      has_checked_in_for_date?(participant_id, check_in_date) ->
        {:error, :already_checked_in}

      participant.challenge.is_template ->
        {:error, :cannot_check_in_template}

      participant.status != :active ->
        {:error, :challenge_not_active}

      # Don't allow check-in for dates before challenge start
      Date.compare(check_in_date, participant.start_date) == :lt ->
        {:error, :date_before_start}

      # Don't allow check-in for dates after challenge end
      participant.end_date && Date.compare(check_in_date, participant.end_date) == :gt ->
        {:error, :date_after_end}

      # Don't allow check-in for future dates
      Date.compare(check_in_date, Date.utc_today()) == :gt ->
        {:error, :future_date}

      true ->
        day_number = Date.diff(check_in_date, participant.start_date) + 1
        challenge = Repo.preload(participant.challenge, phases: :steps)

        {total_tasks, completed_tasks, failed_tasks, skipped_tasks} =
          case challenge.type do
            :predefined ->
              total = count_total_steps(challenge)
              completed = count_completed_steps(participant_id)
              failed = count_failed_steps(participant_id)
              {total, completed, failed, total - completed - failed}

            :custom ->
              today_tasks = get_today_tasks(participant.challenge_id)
              total = length(today_tasks)

              statuses =
                Enum.map(today_tasks, fn task ->
                  get_task_status(participant_id, task.id, check_in_date)
                end)

              completed = Enum.count(statuses, &(&1 == :accomplished))
              failed = Enum.count(statuses, &(&1 == :failed))
              skipped = Enum.count(statuses, &(&1 == :pending))
              {total, completed, failed, skipped}
          end

        check_in_attrs = %{
          participant_id: participant_id,
          challenge_id: participant.challenge_id,
          user_id: participant.user_id,
          day_number: day_number,
          completed_date: check_in_date,
          total_tasks: total_tasks,
          completed_tasks: completed_tasks,
          failed_tasks: failed_tasks,
          skipped_tasks: skipped_tasks,
          note: Map.get(attrs, :note) || Map.get(attrs, "note"),
          mood: Map.get(attrs, :mood) || Map.get(attrs, "mood")
        }

        result =
          %DailyCheckIn{}
          |> DailyCheckIn.changeset(check_in_attrs)
          |> Repo.insert()

        case result do
          {:ok, check_in} ->
            ActivityService.track_activity(participant.user_id, "daily_check_in_submitted",
              challenge_id: participant.challenge_id,
              description: "Day #{day_number}: #{completed_tasks}/#{total_tasks} tasks completed"
            )

            # Check if all days are now checked in → auto-complete
            check_and_auto_complete(participant_id)

            {:ok, check_in}

          error ->
            error
        end
    end
  end

  @doc """
  Gets the feed of daily check-ins for a challenge.
  Returns list ordered by newest first.
  """
  def get_challenge_feed(challenge_id, user_id \\ nil, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)

    from(d in DailyCheckIn,
      where: d.challenge_id == ^challenge_id,
      order_by: [desc: d.completed_date],
      limit: ^limit,
      offset: ^offset
    )
    |> Repo.all()
    |> Repo.preload(:user)
    |> add_check_in_like_info(user_id)
  end

  @doc """
  Gets mood history for a participant's challenge.
  Returns a map of %{day_number => mood_string} for all check-ins.
  """
  def get_mood_history(participant_id) do
    from(d in DailyCheckIn,
      where: d.participant_id == ^participant_id,
      select: {d.day_number, d.mood},
      order_by: [asc: d.day_number]
    )
    |> Repo.all()
    |> Map.new()
  end

  @doc """
  Gets a daily check-in by ID.
  """
  def get_daily_check_in!(id) do
    Repo.get!(DailyCheckIn, id)
    |> Repo.preload([:user, :challenge, :participant])
  end

  # ============================================================================
  # Check-in Likes & Comments
  # ============================================================================

  @doc """
  Reacts to a check-in (like or dislike). Toggle behavior:
  - No existing record → insert with given like_type
  - Same type → remove (toggle off)
  - Opposite type → update to new type
  """
  def react_to_check_in(check_in_id, user_id, like_type \\ "like")
  def react_to_check_in(_check_in_id, nil, _like_type), do: {:error, :guest_not_allowed}

  def react_to_check_in(check_in_id, user_id, like_type) do
    check_in = Repo.get!(DailyCheckIn, check_in_id)

    if check_in.user_id == user_id do
      {:error, :cannot_like_own_check_in}
    else
      case Repo.get_by(CheckInLike, check_in_id: check_in_id, user_id: user_id) do
        nil ->
          %CheckInLike{}
          |> CheckInLike.changeset(%{
            check_in_id: check_in_id,
            user_id: user_id,
            like_type: like_type
          })
          |> Repo.insert()

        %{like_type: ^like_type} = existing ->
          Repo.delete(existing)

        existing ->
          existing
          |> CheckInLike.changeset(%{like_type: like_type})
          |> Repo.update()
      end
    end
  end

  def like_check_in(check_in_id, user_id), do: react_to_check_in(check_in_id, user_id, "like")

  def dislike_check_in(check_in_id, user_id),
    do: react_to_check_in(check_in_id, user_id, "dislike")

  def unlike_check_in(check_in_id, user_id) do
    from(l in CheckInLike, where: l.check_in_id == ^check_in_id and l.user_id == ^user_id)
    |> Repo.delete_all()
  end

  def user_liked_check_in?(check_in_id, user_id) do
    from(l in CheckInLike, where: l.check_in_id == ^check_in_id and l.user_id == ^user_id)
    |> Repo.exists?()
  end

  def list_check_in_comments(check_in_id) do
    from(c in CheckInComment,
      where: c.check_in_id == ^check_in_id,
      order_by: [asc: c.inserted_at],
      preload: [:user]
    )
    |> Repo.all()
  end

  def create_check_in_comment(%{user_id: nil}), do: {:error, :guest_not_allowed}
  def create_check_in_comment(%{"user_id" => nil}), do: {:error, :guest_not_allowed}

  def create_check_in_comment(attrs) do
    %CheckInComment{}
    |> CheckInComment.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, comment} -> {:ok, Repo.preload(comment, :user)}
      error -> error
    end
  end

  def delete_check_in_comment(%CheckInComment{} = comment, user_id) do
    if comment.user_id == user_id do
      Repo.delete(comment)
    else
      {:error, :unauthorized}
    end
  end

  def get_check_in_comment!(id) do
    Repo.get!(CheckInComment, id) |> Repo.preload(:user)
  end

  def add_check_in_like_info(check_ins, user_id) when is_list(check_ins) do
    check_in_ids = Enum.map(check_ins, & &1.id)

    like_counts =
      from(l in CheckInLike, where: l.check_in_id in ^check_in_ids)
      |> group_by([l], l.check_in_id)
      |> select([l], {l.check_in_id, count(l.id)})
      |> Repo.all()
      |> Map.new()

    comment_counts =
      from(c in CheckInComment, where: c.check_in_id in ^check_in_ids)
      |> group_by([c], c.check_in_id)
      |> select([c], {c.check_in_id, count(c.id)})
      |> Repo.all()
      |> Map.new()

    user_likes =
      if user_id do
        from(l in CheckInLike, where: l.check_in_id in ^check_in_ids and l.user_id == ^user_id)
        |> select([l], l.check_in_id)
        |> Repo.all()
        |> MapSet.new()
      else
        MapSet.new()
      end

    Enum.map(check_ins, fn ci ->
      ci
      |> Map.put(:like_count, Map.get(like_counts, ci.id, 0))
      |> Map.put(:comment_count, Map.get(comment_counts, ci.id, 0))
      |> Map.put(:user_liked, MapSet.member?(user_likes, ci.id))
      |> Map.put(:comments, [])
    end)
  end

  # ============================================================================
  # Helper Functions
  # ============================================================================

  defp get_friend_ids(user_id) do
    Accounts.list_friends(user_id)
    |> Enum.map(fn friendship ->
      if friendship.user_id == user_id, do: friendship.friend_id, else: friendship.user_id
    end)
  end

  defp already_participating?(challenge_id, user_id) do
    Repo.exists?(
      from(p in ChallengeParticipant,
        where:
          p.challenge_id == ^challenge_id and p.user_id == ^user_id and
            p.status == :active
      )
    )
  end

  @doc """
  Checks if a user can view a challenge based on visibility settings.
  """
  def can_view_challenge?(%Challenge{} = challenge, user_id) do
    case challenge.visibility do
      :public ->
        true

      :private ->
        challenge.creator_user_id == user_id

      :friends ->
        challenge.creator_user_id == user_id ||
          Accounts.are_friends?(challenge.creator_user_id, user_id)
    end
  end

  @doc """
  Counts active challenges a user is participating in.
  """
  def count_active_challenges(user_id) do
    from(p in ChallengeParticipant,
      where: p.user_id == ^user_id and p.status == :active
    )
    |> Repo.aggregate(:count)
  end

  defp count_total_steps(challenge) do
    from(s in ChallengeStep,
      join: p in ChallengePhase,
      on: s.phase_id == p.id,
      where: p.challenge_id == ^challenge.id
    )
    |> Repo.aggregate(:count)
  end

  defp count_completed_steps(participant_id) do
    from(p in ChallengeStepProgress,
      where: p.participant_id == ^participant_id and p.status == :completed
    )
    |> Repo.aggregate(:count)
  end

  defp count_failed_steps(participant_id) do
    from(p in ChallengeStepProgress,
      where: p.participant_id == ^participant_id and p.status == :failed
    )
    |> Repo.aggregate(:count)
  end

  defp count_tasks_completed_today(participant_id) do
    today = Date.utc_today()

    from(c in ChallengeTaskCompletion,
      where:
        c.participant_id == ^participant_id and c.completed_date == ^today and
          c.status == :accomplished
    )
    |> Repo.aggregate(:count)
  end

  defp count_tasks_failed_today(participant_id) do
    today = Date.utc_today()

    from(c in ChallengeTaskCompletion,
      where:
        c.participant_id == ^participant_id and c.completed_date == ^today and c.status == :failed
    )
    |> Repo.aggregate(:count)
  end

  defp calculate_percentage(completed, total) when total > 0 do
    Float.round(completed / total * 100, 1)
  end

  defp calculate_percentage(_, _), do: 0.0

  defp check_and_complete_challenge(participant) do
    participant = Repo.preload(participant, challenge: :phases)
    total_steps = count_total_steps(participant.challenge)
    completed_steps = count_completed_steps(participant.id)
    today = Date.utc_today()

    # Only auto-complete when ALL steps are done AND we've reached the end date.
    # This prevents premature completion that would hide daily check-in features.
    past_end_date = participant.end_date && Date.compare(today, participant.end_date) != :lt

    if completed_steps >= total_steps and total_steps > 0 and past_end_date do
      participant
      |> ChallengeParticipant.changeset(%{
        status: :completed,
        completed_at: DateTime.utc_now()
      })
      |> Repo.update()

      ActivityService.track_activity(participant.user_id, "challenge_completed",
        challenge_id: participant.challenge_id,
        description: "Completed the challenge!"
      )
    end
  end
end
