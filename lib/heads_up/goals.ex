defmodule HeadsUp.Goals do
  import Ecto.Query, warn: false
  alias HeadsUp.Repo
  alias HeadsUp.Goal
  alias HeadsUp.GoalStep
  alias HeadsUp.GoalLike
  alias HeadsUp.GoalSubscription
  alias HeadsUp.Goals.GoalPost
  alias HeadsUp.Goals.GoalComment
  alias HeadsUp.GoalPostLike
  alias HeadsUp.ActivityService
  alias HeadsUp.Accounts

  def list_goals do
    from(g in Goal,
      where: is_nil(g.deleted_at) and g.moderation_status != "hidden"
    )
    |> Repo.all()
    |> Repo.preload([:group, :user, :goal_steps])
  end

  def list_goals_by_group(group_id, opts \\ []) do
    query = from(g in Goal, where: g.group_id == ^group_id and is_nil(g.deleted_at))

    query =
      if opts[:status] do
        from(g in query, where: g.status == ^opts[:status])
      else
        query
      end

    query =
      if opts[:privacy] do
        from(g in query, where: g.privacy == ^opts[:privacy])
      else
        query
      end

    query
    |> Repo.all()
    |> Repo.preload([:group, :user, :goal_likes, :goal_subscriptions])
    |> add_social_counts()
  end

  def list_public_goals_by_group(group_id) do
    from(g in Goal,
      where:
        g.group_id == ^group_id and g.privacy == :public and is_nil(g.deleted_at) and
          g.moderation_status != "hidden"
    )
    |> Repo.all()
    |> Repo.preload([:group, :user, :goal_likes, :goal_subscriptions])
    |> add_social_counts()
  end

  def list_goals_by_user(user_id) do
    from(g in Goal, where: g.user_id == ^user_id and is_nil(g.deleted_at))
    |> Repo.all()
    |> Repo.preload([:group, :user])
  end

  @doc """
  Counts active goals for a user (used for 3-item limit with challenges).
  """
  def count_active_goals_by_user(user_id) do
    from(g in Goal,
      where: g.user_id == ^user_id and g.status == :active and is_nil(g.deleted_at)
    )
    |> Repo.aggregate(:count)
  end

  def get_goal(id) do
    Repo.get(Goal, id)
  end

  def get_goal!(id) do
    Repo.get!(Goal, id)
    |> Repo.preload([
      :group,
      :user,
      :goal_likes,
      :goal_subscriptions,
      :goal_steps,
      goal_posts: [:user, :step]
    ])
  end

  def get_goal_with_post_likes!(id, user_id \\ nil) do
    goal = get_goal!(id)

    # Add like information to posts
    posts_with_likes = add_post_like_info(goal.goal_posts, user_id)

    # Update goal with enhanced posts
    Map.put(goal, :goal_posts, posts_with_likes)
  end

  def create_goal(attrs \\ %{}) do
    user_id = Map.get(attrs, :user_id) || Map.get(attrs, "user_id")

    # Check active item limit (only for active goals, not paused/frozen)
    status = Map.get(attrs, :status) || Map.get(attrs, "status") || :active

    if user_id && status == :active do
      case HeadsUp.BusinessRules.can_create_active_item?(user_id) do
        {:error, :active_limit_reached} -> {:error, :active_limit_reached}
        :ok -> do_create_goal(attrs)
      end
    else
      do_create_goal(attrs)
    end
  end

  defp do_create_goal(attrs) do
    result =
      %Goal{}
      |> Goal.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, goal} ->
        ActivityService.track_activity(goal.user_id, "goal_created",
          goal_id: goal.id,
          description: "Created goal: #{goal.title}"
        )

        {:ok, goal}

      error ->
        error
    end
  end

  def update_goal(%Goal{} = goal, attrs) do
    goal
    |> Goal.changeset(attrs)
    |> Repo.update()
  end

  def update_goal_with_ownership(%Goal{} = goal, attrs, user_id) do
    cond do
      goal.user_id != user_id ->
        {:error, :unauthorized}

      goal.status == :failed ->
        {:error, :failed}

      goal.is_frozen or goal.status == :frozen ->
        {:error, :frozen}

      true ->
        result = update_goal(goal, attrs)

        case result do
          {:ok, updated_goal} ->
            # Track goal completion if status changed to completed
            if Map.get(attrs, :status) == :completed do
              ActivityService.track_activity(user_id, "goal_completed",
                goal_id: goal.id,
                description: "Completed goal: #{goal.title}"
              )
            else
              # Track general goal update
              ActivityService.track_activity(user_id, "goal_updated",
                goal_id: goal.id,
                description: "Updated goal: #{goal.title}"
              )
            end

            {:ok, updated_goal}

          error ->
            error
        end
    end
  end

  def delete_goal(%Goal{} = goal) do
    Repo.delete(goal)
  end

  def freeze_goal(%Goal{} = goal) do
    goal
    |> Goal.changeset(%{status: :frozen, is_frozen: true})
    |> Repo.update()
  end

  def freeze_goal_with_ownership(%Goal{} = goal, user_id) do
    cond do
      goal.user_id != user_id ->
        {:error, :unauthorized}

      goal.status == :failed ->
        {:error, :failed}

      true ->
        result = freeze_goal(goal)

        case result do
          {:ok, frozen_goal} ->
            ActivityService.track_activity(user_id, "goal_frozen",
              goal_id: goal.id,
              description: "Froze goal: #{goal.title}"
            )

            {:ok, frozen_goal}

          error ->
            error
        end
    end
  end

  def unfreeze_goal(%Goal{} = goal) do
    goal
    |> Goal.changeset(%{status: :active, is_frozen: false})
    |> Repo.update()
  end

  def unfreeze_goal_with_ownership(%Goal{} = goal, user_id) do
    if goal.user_id == user_id do
      unfreeze_goal(goal)
    else
      {:error, :unauthorized}
    end
  end

  def soft_delete_goal(%Goal{} = goal) do
    goal
    |> Goal.changeset(%{status: :deleted, deleted_at: DateTime.utc_now()})
    |> Repo.update()
  end

  def soft_delete_goal_with_ownership(%Goal{} = goal, user_id) do
    if goal.user_id == user_id do
      result = soft_delete_goal(goal)

      case result do
        {:ok, deleted_goal} ->
          ActivityService.track_activity(user_id, "goal_deleted",
            goal_id: goal.id,
            description: "Deleted goal: #{goal.title}"
          )

          {:ok, deleted_goal}

        error ->
          error
      end
    else
      {:error, :unauthorized}
    end
  end

  def restore_goal(%Goal{} = goal) do
    goal
    |> Goal.changeset(%{status: :active, deleted_at: nil})
    |> Repo.update()
  end

  def restore_goal_with_ownership(%Goal{} = goal, user_id) do
    if goal.user_id == user_id do
      restore_goal(goal)
    else
      {:error, :unauthorized}
    end
  end

  def list_deleted_goals_by_user(user_id) do
    from(g in Goal, where: g.user_id == ^user_id and not is_nil(g.deleted_at))
    |> Repo.all()
    |> Repo.preload([:group, :user])
  end

  def change_goal(%Goal{} = goal, attrs \\ %{}) do
    Goal.changeset(goal, attrs)
  end

  def goal_counts(group_id) do
    total = Repo.aggregate(from(g in Goal, where: g.group_id == ^group_id), :count, :id)

    active =
      Repo.aggregate(
        from(g in Goal, where: g.group_id == ^group_id and g.status == :active),
        :count,
        :id
      )

    %{total_goal_amount: total, active_goal_amount: active}
  end

  def get_group_goal_counts(group_ids) do
    total_counts =
      from(g in Goal,
        where: g.group_id in ^group_ids,
        group_by: g.group_id,
        select: {g.group_id, count(g.id)}
      )
      |> Repo.all()
      |> Map.new()

    active_counts =
      from(g in Goal,
        where: g.group_id in ^group_ids and g.status == :active,
        group_by: g.group_id,
        select: {g.group_id, count(g.id)}
      )
      |> Repo.all()
      |> Map.new()

    Enum.reduce(group_ids, %{}, fn group_id, acc ->
      counts = %{
        total_goal_amount: Map.get(total_counts, group_id, 0),
        active_goal_amount: Map.get(active_counts, group_id, 0)
      }

      Map.put(acc, group_id, counts)
    end)
  end

  # Like/Dislike/Subscribe functionality

  @doc """
  Likes or dislikes a goal. Toggle behavior:
  - No existing record → insert with given like_type
  - Existing record with same type → remove (toggle off)
  - Existing record with opposite type → update to new type
  """
  def react_to_goal(goal_id, user_id, like_type \\ "like")
  def react_to_goal(_goal_id, nil, _like_type), do: {:error, :guest_not_allowed}

  def react_to_goal(goal_id, user_id, like_type) do
    goal = get_goal!(goal_id)

    if goal.user_id == user_id do
      {:error, :cannot_like_own_goal}
    else
      case Repo.get_by(GoalLike, goal_id: goal_id, user_id: user_id) do
        nil ->
          %GoalLike{}
          |> GoalLike.changeset(%{goal_id: goal_id, user_id: user_id, like_type: like_type})
          |> Repo.insert()

        %{like_type: ^like_type} = existing ->
          Repo.delete(existing)

        existing ->
          existing
          |> GoalLike.changeset(%{like_type: like_type})
          |> Repo.update()
      end
    end
  end

  def like_goal(goal_id, user_id), do: react_to_goal(goal_id, user_id, "like")
  def dislike_goal(goal_id, user_id), do: react_to_goal(goal_id, user_id, "dislike")

  def unlike_goal(goal_id, user_id) do
    case Repo.get_by(GoalLike, goal_id: goal_id, user_id: user_id) do
      nil -> {:error, :not_found}
      like -> Repo.delete(like)
    end
  end

  def subscribe_to_goal(goal_id, user_id) do
    # Check if user owns the goal
    goal = get_goal!(goal_id)

    cond do
      goal.user_id == user_id ->
        {:error, :cannot_subscribe_to_own_goal}

      goal.privacy == :private ->
        {:error, :access_denied}

      goal.privacy == :friends and not Accounts.are_friends?(goal.user_id, user_id) ->
        {:error, :must_be_friends}

      true ->
        %GoalSubscription{}
        |> GoalSubscription.changeset(%{goal_id: goal_id, user_id: user_id})
        |> Repo.insert()
    end
  end

  def unsubscribe_from_goal(goal_id, user_id) do
    case Repo.get_by(GoalSubscription, goal_id: goal_id, user_id: user_id) do
      nil -> {:error, :not_found}
      subscription -> Repo.delete(subscription)
    end
  end

  def user_liked_goal?(goal_id, user_id) do
    Repo.exists?(from(gl in GoalLike, where: gl.goal_id == ^goal_id and gl.user_id == ^user_id))
  end

  @doc """
  Gets a user's reaction type for a goal. Returns "like", "dislike", or nil.
  """
  def get_user_goal_reaction(goal_id, user_id) do
    from(gl in GoalLike,
      where: gl.goal_id == ^goal_id and gl.user_id == ^user_id,
      select: gl.like_type
    )
    |> Repo.one()
  end

  def user_subscribed_to_goal?(goal_id, user_id) do
    Repo.exists?(
      from(gs in GoalSubscription, where: gs.goal_id == ^goal_id and gs.user_id == ^user_id)
    )
  end

  # Goal Posts functionality
  def list_goal_posts(goal_id) do
    from(p in GoalPost,
      where: p.goal_id == ^goal_id and p.moderation_status != "hidden",
      order_by: [desc: p.inserted_at]
    )
    |> Repo.all()
    |> Repo.preload([:user])
  end

  def create_goal_post(attrs \\ %{}) do
    %GoalPost{}
    |> GoalPost.changeset(attrs)
    |> Repo.insert()
  end

  def create_goal_post_with_ownership(attrs, user_id) do
    goal_id = attrs["goal_id"] || attrs[:goal_id]
    goal = get_goal!(goal_id)

    # Only goal owners can create posts, and goal must not be frozen or failed
    cond do
      goal.user_id != user_id ->
        {:error, :unauthorized}

      goal.status == :failed ->
        {:error, :failed}

      goal.is_frozen or goal.status == :frozen ->
        {:error, :frozen}

      true ->
        result = create_goal_post(attrs)

        case result do
          {:ok, post} ->
            ActivityService.track_activity(user_id, "post_created",
              goal_id: goal_id,
              post_id: post.id,
              description: "Created a post in goal: #{goal.title}"
            )

            {:ok, post}

          error ->
            error
        end
    end
  end

  def delete_goal_post(%GoalPost{} = post) do
    Repo.delete(post)
  end

  def update_goal_post(%GoalPost{} = post, attrs) do
    post
    |> GoalPost.changeset(attrs)
    |> Repo.update()
  end

  def update_goal_post_with_ownership(%GoalPost{} = post, attrs, user_id) do
    if post.user_id == user_id do
      update_goal_post(post, attrs)
    else
      {:error, :unauthorized}
    end
  end

  def delete_goal_post_with_ownership(%GoalPost{} = post, user_id) do
    if post.user_id == user_id do
      delete_goal_post(post)
    else
      {:error, :unauthorized}
    end
  end

  def add_social_counts(goals) do
    Enum.map(goals, fn goal ->
      like_count = length(goal.goal_likes)
      subscriber_count = length(goal.goal_subscriptions)
      post_count = if Ecto.assoc_loaded?(goal.goal_posts), do: length(goal.goal_posts), else: 0

      goal
      |> Map.put(:like_count, like_count)
      |> Map.put(:subscriber_count, subscriber_count)
      |> Map.put(:post_count, post_count)
    end)
  end

  # Goal Steps functionality
  def list_goal_steps(goal_id) do
    from(s in GoalStep,
      where: s.goal_id == ^goal_id,
      order_by: [asc: s.order]
    )
    |> Repo.all()
  end

  def create_goal_step(attrs \\ %{}) do
    %GoalStep{}
    |> GoalStep.changeset(attrs)
    |> Repo.insert()
  end

  def create_goal_step_with_ownership(attrs, user_id) do
    goal_id = attrs["goal_id"] || attrs[:goal_id]
    goal = get_goal!(goal_id)

    if goal.user_id == user_id do
      create_goal_step(attrs)
    else
      {:error, :unauthorized}
    end
  end

  def update_goal_step(%GoalStep{} = step, attrs) do
    step
    |> GoalStep.changeset(attrs)
    |> Repo.update()
  end

  def update_goal_step_with_ownership(%GoalStep{} = step, attrs, user_id) do
    step = Repo.preload(step, :goal)

    if step.goal.user_id == user_id do
      update_goal_step(step, attrs)
    else
      {:error, :unauthorized}
    end
  end

  def delete_goal_step(%GoalStep{} = step) do
    Repo.delete(step)
  end

  def delete_goal_step_with_ownership(%GoalStep{} = step, user_id) do
    step = Repo.preload(step, :goal)

    if step.goal.user_id == user_id do
      delete_goal_step(step)
    else
      {:error, :unauthorized}
    end
  end

  def get_goal_step!(id) do
    Repo.get!(GoalStep, id)
  end

  def toggle_goal_step_completion(%GoalStep{} = step) do
    update_goal_step(step, %{completed: !step.completed})
  end

  def toggle_goal_step_completion_with_ownership(%GoalStep{} = step, user_id) do
    step = Repo.preload(step, :goal)

    if step.goal.user_id == user_id do
      toggle_goal_step_completion(step)
    else
      {:error, :unauthorized}
    end
  end

  def get_next_step_order(goal_id) do
    case Repo.aggregate(from(s in GoalStep, where: s.goal_id == ^goal_id), :max, :order) do
      nil -> 1
      max_order -> max_order + 1
    end
  end

  def count_goal_steps(goal_id) do
    total = Repo.aggregate(from(s in GoalStep, where: s.goal_id == ^goal_id), :count, :id)

    completed =
      Repo.aggregate(
        from(s in GoalStep, where: s.goal_id == ^goal_id and s.completed == true),
        :count,
        :id
      )

    {completed, total}
  end

  def reorder_goal_steps(goal_id, step_ids) do
    Enum.with_index(step_ids, 1)
    |> Enum.each(fn {step_id, order} ->
      from(s in GoalStep, where: s.id == ^step_id and s.goal_id == ^goal_id)
      |> Repo.update_all(set: [order: order])
    end)
  end

  # Goal Post Like/Dislike functions

  @doc """
  Reacts to a post (like or dislike). Toggle behavior same as react_to_goal.
  """
  def react_to_post(post_id, user_id, like_type \\ "like")
  def react_to_post(_post_id, nil, _like_type), do: {:error, :guest_not_allowed}

  def react_to_post(post_id, user_id, like_type) do
    post = Repo.get!(GoalPost, post_id) |> Repo.preload(:user)

    if post.user_id == user_id do
      {:error, :cannot_like_own_post}
    else
      case Repo.get_by(GoalPostLike, goal_post_id: post_id, user_id: user_id) do
        nil ->
          result =
            %GoalPostLike{}
            |> GoalPostLike.changeset(%{
              goal_post_id: post_id,
              user_id: user_id,
              like_type: like_type
            })
            |> Repo.insert()

          case result do
            {:ok, like} ->
              ActivityService.track_activity(user_id, "post_liked",
                post_id: post_id,
                like_id: like.id,
                description: "#{String.capitalize(like_type)}d a post"
              )

              ActivityService.track_activity(post.user_id, "post_received_like",
                post_id: post_id,
                like_id: like.id,
                description: "Received a #{like_type} on post"
              )

              {:ok, like}

            error ->
              error
          end

        %{like_type: ^like_type} = existing ->
          Repo.delete(existing)

        existing ->
          existing
          |> GoalPostLike.changeset(%{like_type: like_type})
          |> Repo.update()
      end
    end
  end

  def like_post(post_id, user_id), do: react_to_post(post_id, user_id, "like")
  def dislike_post(post_id, user_id), do: react_to_post(post_id, user_id, "dislike")

  def unlike_post(post_id, user_id) do
    from(l in GoalPostLike, where: l.goal_post_id == ^post_id and l.user_id == ^user_id)
    |> Repo.delete_all()
  end

  def user_liked_post?(post_id, user_id) do
    from(l in GoalPostLike, where: l.goal_post_id == ^post_id and l.user_id == ^user_id)
    |> Repo.exists?()
  end

  def get_post_like_count(post_id) do
    from(l in GoalPostLike, where: l.goal_post_id == ^post_id)
    |> Repo.aggregate(:count)
  end

  def add_post_like_info(posts, user_id) when is_list(posts) do
    post_ids = Enum.map(posts, & &1.id)

    # Get like counts for all posts
    like_counts =
      from(l in GoalPostLike, where: l.goal_post_id in ^post_ids)
      |> group_by([l], l.goal_post_id)
      |> select([l], {l.goal_post_id, count(l.id)})
      |> Repo.all()
      |> Map.new()

    # Get comment counts for all posts (prevents N+1)
    comment_counts = comment_counts_by_post_ids(post_ids)

    # Get user likes for all posts (if user_id is provided)
    user_likes =
      if user_id do
        from(l in GoalPostLike, where: l.goal_post_id in ^post_ids and l.user_id == ^user_id)
        |> select([l], l.goal_post_id)
        |> Repo.all()
        |> MapSet.new()
      else
        MapSet.new()
      end

    # Add like and comment info to each post
    Enum.map(posts, fn post ->
      post
      |> Map.put(:like_count, Map.get(like_counts, post.id, 0))
      |> Map.put(:comment_count, Map.get(comment_counts, post.id, 0))
      |> Map.put(:user_liked, MapSet.member?(user_likes, post.id))
      |> Map.put(:comments, [])
    end)
  end

  # Goal Failure functionality
  def fail_goal(%Goal{} = goal, failure_reason) when is_binary(failure_reason) do
    goal
    |> Goal.changeset(%{
      status: :failed,
      failure_reason: failure_reason,
      failed_at: DateTime.utc_now()
    })
    |> Repo.update()
  end

  def fail_goal_with_ownership(%Goal{} = goal, failure_reason, user_id) do
    if goal.user_id == user_id do
      case fail_goal(goal, failure_reason) do
        {:ok, failed_goal} ->
          # Track goal failure activity
          ActivityService.track_activity(user_id, "goal_failed",
            goal_id: goal.id,
            description: "Failed goal: #{goal.title} - #{failure_reason}"
          )

          # Create a post about the failure
          case create_goal_post(%{
                 goal_id: failed_goal.id,
                 user_id: user_id,
                 content: failure_reason,
                 # Use challenge type for failure posts
                 post_type: :challenge
               }) do
            {:ok, _post} -> {:ok, failed_goal}
            # Don't fail the goal failure if post creation fails
            {:error, _} -> {:ok, failed_goal}
          end

        error ->
          error
      end
    else
      {:error, :unauthorized}
    end
  end

  # Goal Post Comments

  @doc """
  Lists all comments for a goal post.
  """
  def list_comments(goal_post_id) do
    from(c in GoalComment,
      where: c.goal_post_id == ^goal_post_id,
      order_by: [asc: c.inserted_at],
      preload: [:user]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single comment.
  Raises if not found.
  """
  def get_comment!(id), do: Repo.get!(GoalComment, id) |> Repo.preload(:user)

  @doc """
  Creates a comment on a goal post.
  """
  def create_comment(attrs \\ %{}) do
    user_id = Map.get(attrs, :user_id) || Map.get(attrs, "user_id")

    if is_nil(user_id) do
      {:error, :guest_not_allowed}
    else
      %GoalComment{}
      |> GoalComment.changeset(attrs)
      |> Repo.insert()
      |> case do
        {:ok, comment} -> {:ok, Repo.preload(comment, :user)}
        error -> error
      end
    end
  end

  @doc """
  Deletes a comment with ownership check.
  Only the comment author can delete their comment.
  """
  def delete_comment(%GoalComment{} = comment, user_id) do
    if comment.user_id == user_id do
      Repo.delete(comment)
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Returns the comment count for a goal post.
  """
  def count_comments(goal_post_id) do
    from(c in GoalComment, where: c.goal_post_id == ^goal_post_id, select: count(c.id))
    |> Repo.one()
  end

  @doc """
  Returns comment counts for multiple posts in a single query.
  Prevents N+1 queries when displaying posts with comment counts.
  """
  def comment_counts_by_post_ids(post_ids) when is_list(post_ids) do
    from(c in GoalComment,
      where: c.goal_post_id in ^post_ids,
      group_by: c.goal_post_id,
      select: {c.goal_post_id, count(c.id)}
    )
    |> Repo.all()
    |> Map.new()
  end
end
