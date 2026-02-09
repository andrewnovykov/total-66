defmodule HeadsUpWeb.Api.ChallengeJSON do
  def index(%{challenges: challenges, current_user_id: current_user_id}) do
    %{
      data: Enum.map(challenges, &render_challenge_summary(&1, current_user_id)),
      meta: %{count: length(challenges)}
    }
  end

  def show(%{challenge: challenge, current_user_id: current_user_id, participant: participant}) do
    %{data: render_challenge_detail(challenge, current_user_id, participant)}
  end

  def participant(%{participant: participant}) do
    %{data: render_participant(participant)}
  end

  def progress(%{progress: progress}) do
    %{data: progress}
  end

  def today(%{today_items: {type, items}}) do
    %{data: %{type: type, items: items}}
  end

  def today(%{today_items: today_items}) do
    %{data: today_items}
  end

  def feed(%{feed: feed, current_user_id: current_user_id}) do
    %{data: Enum.map(feed, &render_check_in(&1, current_user_id))}
  end

  def check_in(%{check_in: check_in, current_user_id: current_user_id}) do
    %{data: render_check_in(check_in, current_user_id)}
  end

  def check_in_comment(%{comment: comment}) do
    %{data: render_comment(comment)}
  end

  def categories(%{categories: categories}) do
    %{data: Enum.map(categories, &render_category/1)}
  end

  def action_success(%{message: message}) do
    %{success: true, message: message}
  end

  def error(%{message: message}) do
    %{success: false, error: %{message: message}}
  end

  def changeset_error(%{changeset: changeset}) do
    %{
      success: false,
      error: %{
        message: "Validation failed",
        details: translate_errors(changeset)
      }
    }
  end

  # Private renderers

  defp render_challenge_summary(challenge, current_user_id) do
    participant_count = length(challenge.participants || [])

    is_participant =
      current_user_id && Enum.any?(challenge.participants || [], &(&1.user_id == current_user_id))

    %{
      id: challenge.id,
      title: challenge.title,
      description: challenge.description,
      type: challenge.type,
      visibility: challenge.visibility,
      status: challenge.status,
      image_path: challenge.image_path,
      is_template: challenge.is_template,
      duration_days: challenge.duration_days,
      start_date: challenge.start_date,
      end_date: challenge.end_date,
      participant_count: participant_count,
      is_participant: is_participant,
      is_owner: current_user_id == challenge.creator_user_id,
      creator: if(challenge.creator, do: render_user(challenge.creator), else: nil),
      category: if(challenge.category, do: render_category(challenge.category), else: nil),
      created_at: challenge.inserted_at
    }
  end

  defp render_challenge_detail(challenge, current_user_id, participant) do
    base = render_challenge_summary(challenge, current_user_id)

    phases =
      if challenge.phases do
        Enum.map(challenge.phases, &render_phase/1) |> Enum.sort_by(& &1.order_index)
      else
        []
      end

    tasks =
      if challenge.tasks do
        Enum.map(challenge.tasks, &render_task/1)
      else
        []
      end

    Map.merge(base, %{
      failure_reason: challenge.failure_reason,
      failed_at: challenge.failed_at,
      template_id: challenge.template_id,
      phases: phases,
      tasks: tasks,
      my_participation: if(participant, do: render_participant(participant), else: nil)
    })
  end

  defp render_phase(phase) do
    steps =
      if phase.steps do
        Enum.map(phase.steps, &render_step/1) |> Enum.sort_by(& &1.order_index)
      else
        []
      end

    %{
      id: phase.id,
      title: phase.title,
      description: phase.description,
      order_index: phase.order_index,
      start_date: phase.start_date,
      end_date: phase.end_date,
      start_day: phase.start_day,
      end_day: phase.end_day,
      steps: steps
    }
  end

  defp render_step(step) do
    %{
      id: step.id,
      title: step.title,
      description: step.description,
      order_index: step.order_index,
      schedule_type: step.schedule_type,
      schedule_weekdays: step.schedule_weekdays
    }
  end

  defp render_task(task) do
    %{
      id: task.id,
      title: task.title,
      description: task.description,
      schedule_type: task.schedule_type,
      schedule_weekdays: task.schedule_weekdays
    }
  end

  defp render_participant(participant) do
    %{
      id: participant.id,
      status: participant.status,
      start_date: participant.start_date,
      end_date: participant.end_date,
      joined_at: participant.joined_at,
      completed_at: participant.completed_at,
      failure_reason: participant.failure_reason,
      failed_at: participant.failed_at
    }
  end

  defp render_check_in(check_in, current_user_id) do
    like_count = length(check_in.check_in_likes || [])

    is_liked =
      current_user_id &&
        Enum.any?(check_in.check_in_likes || [], &(&1.user_id == current_user_id))

    comments =
      if check_in.check_in_comments do
        Enum.map(check_in.check_in_comments, &render_comment/1)
      else
        []
      end

    %{
      id: check_in.id,
      day_number: check_in.day_number,
      completed_date: check_in.completed_date,
      total_tasks: check_in.total_tasks,
      completed_tasks: check_in.completed_tasks,
      failed_tasks: check_in.failed_tasks,
      skipped_tasks: check_in.skipped_tasks,
      note: check_in.note,
      mood: check_in.mood,
      like_count: like_count,
      is_liked: is_liked,
      user: if(check_in.user, do: render_user(check_in.user), else: nil),
      comments: comments,
      created_at: check_in.inserted_at
    }
  end

  defp render_comment(comment) do
    %{
      id: comment.id,
      content: comment.content,
      user: if(comment.user, do: render_user(comment.user), else: nil),
      created_at: comment.inserted_at
    }
  end

  defp render_category(category) do
    %{
      id: category.id,
      name: category.name,
      description: Map.get(category, :description, nil),
      image_path: Map.get(category, :image_path, nil)
    }
  end

  defp render_user(user) do
    %{
      id: user.id,
      name: user.name,
      username: user.user_name,
      image_path: user.image_path,
      level: user.level
    }
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
