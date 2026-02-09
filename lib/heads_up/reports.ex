defmodule HeadsUp.Reports do
  import Ecto.Query, warn: false
  alias HeadsUp.Repo
  alias HeadsUp.Reports.Report
  alias HeadsUp.Goal
  alias HeadsUp.Goals.GoalPost
  alias HeadsUp.Users
  alias HeadsUp.Challenges.Challenge

  @auto_hide_threshold 3

  # ============================================================================
  # Create reports
  # ============================================================================

  def report_goal(goal_id, user_id, attrs) do
    goal = Repo.get(Goal, goal_id)

    cond do
      is_nil(goal) ->
        {:error, :not_found}

      goal.user_id == user_id ->
        {:error, :cannot_report_own}

      true ->
        %Report{}
        |> Report.changeset(Map.merge(attrs, %{goal_id: goal_id, user_id: user_id}))
        |> Repo.insert()
        |> handle_insert_result(&update_goal_report_count/1, goal_id)
    end
  end

  def report_post(post_id, user_id, attrs) do
    post = Repo.get(GoalPost, post_id)

    cond do
      is_nil(post) ->
        {:error, :not_found}

      post.user_id == user_id ->
        {:error, :cannot_report_own}

      true ->
        %Report{}
        |> Report.changeset(Map.merge(attrs, %{post_id: post_id, user_id: user_id}))
        |> Repo.insert()
        |> handle_insert_result(&update_post_report_count/1, post_id)
    end
  end

  def report_user(reported_user_id, reporter_id, attrs) do
    reported_user = Repo.get(Users, reported_user_id)

    cond do
      is_nil(reported_user) ->
        {:error, :not_found}

      reported_user_id == reporter_id ->
        {:error, :cannot_report_own}

      true ->
        %Report{}
        |> Report.changeset(Map.merge(attrs, %{reported_user_id: reported_user_id, user_id: reporter_id}))
        |> Repo.insert()
        |> handle_insert_result(&update_user_report_count/1, reported_user_id)
    end
  end

  def report_challenge(challenge_id, user_id, attrs) do
    challenge = Repo.get(Challenge, challenge_id)

    cond do
      is_nil(challenge) ->
        {:error, :not_found}

      challenge.creator_user_id == user_id ->
        {:error, :cannot_report_own}

      true ->
        %Report{}
        |> Report.changeset(Map.merge(attrs, %{challenge_id: challenge_id, user_id: user_id}))
        |> Repo.insert()
        |> handle_insert_result(&update_challenge_report_count/1, challenge_id)
    end
  end

  # ============================================================================
  # Query helpers
  # ============================================================================

  def has_reported_goal?(goal_id, user_id) do
    from(r in Report, where: r.goal_id == ^goal_id and r.user_id == ^user_id)
    |> Repo.exists?()
  end

  def has_reported_post?(post_id, user_id) do
    from(r in Report, where: r.post_id == ^post_id and r.user_id == ^user_id)
    |> Repo.exists?()
  end

  def has_reported_user?(reported_user_id, reporter_id) do
    from(r in Report, where: r.reported_user_id == ^reported_user_id and r.user_id == ^reporter_id)
    |> Repo.exists?()
  end

  def has_reported_challenge?(challenge_id, user_id) do
    from(r in Report, where: r.challenge_id == ^challenge_id and r.user_id == ^user_id)
    |> Repo.exists?()
  end

  def goal_report_count(goal_id) do
    from(r in Report, where: r.goal_id == ^goal_id)
    |> Repo.aggregate(:count)
  end

  def post_report_count(post_id) do
    from(r in Report, where: r.post_id == ^post_id)
    |> Repo.aggregate(:count)
  end

  def user_report_count(user_id) do
    from(r in Report, where: r.reported_user_id == ^user_id)
    |> Repo.aggregate(:count)
  end

  def challenge_report_count(challenge_id) do
    from(r in Report, where: r.challenge_id == ^challenge_id)
    |> Repo.aggregate(:count)
  end

  def goal_hidden?(goal_id), do: goal_report_count(goal_id) >= @auto_hide_threshold
  def post_hidden?(post_id), do: post_report_count(post_id) >= @auto_hide_threshold
  def user_hidden?(user_id), do: user_report_count(user_id) >= @auto_hide_threshold
  def challenge_hidden?(challenge_id), do: challenge_report_count(challenge_id) >= @auto_hide_threshold

  # ============================================================================
  # Auto-hide logic
  # ============================================================================

  defp update_goal_report_count(goal_id) do
    count = goal_report_count(goal_id)
    status = if count >= @auto_hide_threshold, do: "hidden", else: "flagged"

    from(g in Goal, where: g.id == ^goal_id)
    |> Repo.update_all(set: [report_count: count, moderation_status: status])
  end

  defp update_post_report_count(post_id) do
    count = post_report_count(post_id)
    status = if count >= @auto_hide_threshold, do: "hidden", else: "flagged"

    from(p in GoalPost, where: p.id == ^post_id)
    |> Repo.update_all(set: [report_count: count, moderation_status: status])
  end

  defp update_user_report_count(user_id) do
    count = user_report_count(user_id)
    status = if count >= @auto_hide_threshold, do: "hidden", else: "flagged"

    from(u in Users, where: u.id == ^user_id)
    |> Repo.update_all(set: [report_count: count, moderation_status: status])
  end

  defp update_challenge_report_count(challenge_id) do
    count = challenge_report_count(challenge_id)
    status = if count >= @auto_hide_threshold, do: "hidden", else: "flagged"

    from(c in Challenge, where: c.id == ^challenge_id)
    |> Repo.update_all(set: [report_count: count, moderation_status: status])
  end

  defp handle_insert_result(result, update_fn, target_id) do
    case result do
      {:ok, report} ->
        update_fn.(target_id)
        {:ok, report}

      {:error, %Ecto.Changeset{errors: errors} = changeset} ->
        if has_unique_constraint_error?(errors) do
          {:error, :already_reported}
        else
          {:error, changeset}
        end
    end
  end

  defp has_unique_constraint_error?(errors) do
    Enum.any?(errors, fn
      {_field, {_msg, opts}} -> Keyword.get(opts, :constraint) == :unique
      _ -> false
    end)
  end

  # ============================================================================
  # Admin functions
  # ============================================================================

  def list_reports(opts \\ []) do
    query = from(r in Report, order_by: [desc: r.inserted_at])

    query =
      case opts[:type] do
        :goal -> from(r in query, where: not is_nil(r.goal_id))
        :post -> from(r in query, where: not is_nil(r.post_id))
        :user -> from(r in query, where: not is_nil(r.reported_user_id))
        :challenge -> from(r in query, where: not is_nil(r.challenge_id))
        _ -> query
      end

    query
    |> Repo.all()
    |> Repo.preload([:user, :goal, :post, :reported_user, :challenge])
  end

  def get_report!(id) do
    Repo.get!(Report, id)
    |> Repo.preload([:user, :goal, :post, :reported_user, :challenge])
  end
end
