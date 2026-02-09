defmodule HeadsUpWeb.PageController do
  use HeadsUpWeb, :controller
  alias HeadsUp.Repo
  import Ecto.Query

  def home(conn, _params) do
    # Get trending goals (most liked + subscribed)
    trending_goals = get_trending_goals()

    # Get popular groups (most goals)
    popular_groups = get_popular_groups()

    # Get user spotlights (highest level)
    user_spotlights = get_user_spotlights()

    # Get challenge categories
    challenge_categories = get_challenge_categories()

    conn
    |> assign(:trending_goals, trending_goals)
    |> assign(:popular_groups, popular_groups)
    |> assign(:user_spotlights, user_spotlights)
    |> assign(:challenge_categories, challenge_categories)
    |> render(:home)
  end

  defp get_trending_goals do
    goals =
      from(g in HeadsUp.Goal,
        where: g.privacy == :public,
        left_join: l in HeadsUp.GoalLike,
        on: l.goal_id == g.id,
        left_join: s in HeadsUp.GoalSubscription,
        on: s.goal_id == g.id,
        group_by: g.id,
        order_by: [desc: count(l.id, :distinct) + count(s.id, :distinct)],
        limit: 6,
        preload: [:user, :group, :goal_likes, :goal_subscriptions, :goal_posts]
      )
      |> Repo.all()

    Enum.map(goals, fn goal ->
      goal
      |> Map.put(:like_count, length(goal.goal_likes))
      |> Map.put(:subscriber_count, length(goal.goal_subscriptions))
      |> Map.put(:post_count, length(goal.goal_posts))
    end)
  end

  defp get_popular_groups do
    # Get published groups with the most goals
    from(g in HeadsUp.Group,
      where: g.status == :published,
      left_join: goal in HeadsUp.Goal,
      on: goal.group_id == g.id,
      group_by: g.id,
      order_by: [desc: count(goal.id)],
      limit: 3
    )
    |> Repo.all()
    |> Enum.map(fn group ->
      goal_count =
        Repo.aggregate(from(g in HeadsUp.Goal, where: g.group_id == ^group.id), :count, :id)

      Map.put(group, :goal_count, goal_count)
    end)
  end

  defp get_user_spotlights do
    # Get users with highest levels
    from(u in HeadsUp.Users,
      order_by: [desc: u.level],
      limit: 3
    )
    |> Repo.all()
    |> Enum.map(fn user ->
      # Get their latest goal achievement if any
      latest_achievement = get_user_latest_achievement(user.id)
      Map.put(user, :latest_achievement, latest_achievement)
    end)
  end

  defp get_user_latest_achievement(user_id) do
    from(g in HeadsUp.Goal,
      where: g.user_id == ^user_id and g.status == :completed,
      order_by: [desc: g.updated_at],
      limit: 1,
      select: g.title
    )
    |> Repo.one()
  end

  defp get_challenge_categories do
    from(c in HeadsUp.Challenges.ChallengeCategory,
      where: c.status == :active,
      left_join: ch in HeadsUp.Challenges.Challenge,
      on: ch.category_id == c.id and ch.is_template == true and ch.status == :active,
      group_by: c.id,
      order_by: [asc: c.order, asc: c.name],
      select: %{id: c.id, name: c.name, challenge_count: count(ch.id)}
    )
    |> Repo.all()
  end
end
