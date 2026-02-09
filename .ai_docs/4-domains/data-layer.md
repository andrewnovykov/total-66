# Data Layer Patterns - Domain Documentation

## Overview

The data layer in HeadsUp uses Ecto for database operations. All Repo calls are made from context modules, never from LiveViews or controllers. The application uses PostgreSQL with Ecto.Adapters.SQL.

## Repository Configuration

```elixir
# File: /lib/heads_up/repo.ex
defmodule HeadsUp.Repo do
  use Ecto.Repo,
    otp_app: :heads_up,
    adapter: Ecto.Adapters.Postgres
end
```

## Query Composition Patterns

### Basic from Query

```elixir
# File: /lib/heads_up/goals.ex
def list_goals do
  from(g in Goal, where: is_nil(g.deleted_at))
  |> Repo.all()
  |> Repo.preload([:group, :user, :goal_steps])
end
```

### Query with Filters

```elixir
# File: /lib/heads_up/goals.ex
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
```

### Complex Query with Joins

```elixir
# File: /lib/heads_up/feed_service.ex
def get_user_feed(user_id, opts \\ []) do
  limit = Keyword.get(opts, :limit, 20)
  offset = Keyword.get(opts, :offset, 0)

  activities =
    from(a in UserActivity,
      join: u in Users,
      on: a.user_id == u.id,
      where: a.user_id in ^all_user_ids,
      where:
        a.activity_type in [
          "goal_created",
          "goal_completed",
          "goal_failed",
          "post_created",
          "user_followed",
          "friend_request_accepted"
        ],
      order_by: [desc: a.inserted_at],
      limit: ^limit,
      offset: ^offset,
      preload: [:user, :goal, :post],
      select: a
    )
    |> Repo.all()

  Enum.map(activities, &format_activity_for_feed/1)
end
```

### Query with Fragments

```elixir
# File: /lib/heads_up/feed_service.ex
friend_ids =
  from(f in Friendship,
    where: (f.user_id == ^user_id or f.friend_id == ^user_id) and f.status == "accepted",
    select:
      fragment(
        "CASE WHEN ? = ? THEN ? ELSE ? END",
        f.user_id,
        ^user_id,
        f.friend_id,
        f.user_id
      )
  )
  |> Repo.all()
```

### Query with Date Fragments

```elixir
# File: /lib/heads_up/activity_service.ex
activities =
  from(a in UserActivity,
    where: a.user_id == ^user_id and fragment("DATE(?)", a.inserted_at) >= ^start_date,
    select: {fragment("DATE(?)", a.inserted_at), count(a.id)},
    group_by: fragment("DATE(?)", a.inserted_at)
  )
  |> Repo.all()
  |> Map.new()
```

### Query with Group By and Aggregation

```elixir
# File: /lib/heads_up/goals.ex
def add_post_like_info(posts, user_id) when is_list(posts) do
  post_ids = Enum.map(posts, & &1.id)

  like_counts =
    from(l in GoalPostLike, where: l.goal_post_id in ^post_ids)
    |> group_by([l], l.goal_post_id)
    |> select([l], {l.goal_post_id, count(l.id)})
    |> Repo.all()
    |> Map.new()

  user_likes =
    if user_id do
      from(l in GoalPostLike, where: l.goal_post_id in ^post_ids and l.user_id == ^user_id)
      |> select([l], l.goal_post_id)
      |> Repo.all()
      |> MapSet.new()
    else
      MapSet.new()
    end

  # Add like info to each post
  Enum.map(posts, fn post ->
    post
    |> Map.put(:like_count, Map.get(like_counts, post.id, 0))
    |> Map.put(:user_liked, MapSet.member?(user_likes, post.id))
  end)
end
```

## Repo Functions

### Repo.all

```elixir
def list_users do
  Repo.all(Users)
end

def list_goals do
  from(g in Goal, where: is_nil(g.deleted_at))
  |> Repo.all()
end
```

### Repo.get and Repo.get!

```elixir
def get_goal(id) do
  Repo.get(Goal, id)
end

def get_goal!(id) do
  Repo.get!(Goal, id)
  |> Repo.preload([...])
end
```

### Repo.get_by

```elixir
def get_user_by_username(username) do
  Repo.get_by(Users, user_name: username)
end

def get_friend_request(user_id, friend_id) do
  Repo.get_by(Friendship, user_id: user_id, friend_id: friend_id)
end
```

### Repo.one

```elixir
total_goals =
  from(a in UserActivity,
    where: a.user_id == ^user_id and a.activity_type == "goal_created",
    select: count(a.id)
  )
  |> Repo.one()
```

### Repo.insert

```elixir
def create_goal(attrs \\ %{}) do
  %Goal{}
  |> Goal.changeset(attrs)
  |> Repo.insert()
end
```

### Repo.insert!

```elixir
Repo.insert!(user_token)

%UserLevel{}
|> UserLevel.changeset(%{user_id: user_id, level: new_level, xp: new_xp, level_name: level_name})
|> Repo.insert!()
```

### Repo.update and Repo.update!

```elixir
def update_goal(%Goal{} = goal, attrs) do
  goal
  |> Goal.changeset(attrs)
  |> Repo.update()
end

user
|> Users.changeset(%{xp: new_xp, level: new_level})
|> Repo.update!()
```

### Repo.delete

```elixir
def delete_goal(%Goal{} = goal) do
  Repo.delete(goal)
end

case Repo.get_by(GoalLike, goal_id: goal_id, user_id: user_id) do
  nil -> {:error, :not_found}
  like -> Repo.delete(like)
end
```

### Repo.delete_all

```elixir
def unlike_post(post_id, user_id) do
  from(l in GoalPostLike, where: l.goal_post_id == ^post_id and l.user_id == ^user_id)
  |> Repo.delete_all()
end

from(f in Friendship,
  where:
    (f.user_id == ^user_id and f.friend_id == ^friend_id) or
      (f.user_id == ^friend_id and f.friend_id == ^user_id),
  where: f.status == "accepted"
)
|> Repo.delete_all()
```

### Repo.update_all

```elixir
def reorder_goal_steps(goal_id, step_ids) do
  Enum.with_index(step_ids, 1)
  |> Enum.each(fn {step_id, order} ->
    from(s in GoalStep, where: s.id == ^step_id and s.goal_id == ^goal_id)
    |> Repo.update_all(set: [order: order])
  end)
end
```

### Repo.exists?

```elixir
def user_liked_goal?(goal_id, user_id) do
  Repo.exists?(from(gl in GoalLike, where: gl.goal_id == ^goal_id and gl.user_id == ^user_id))
end

def is_following?(follower_id, following_id) do
  Repo.exists?(
    from f in UserFollow,
      where: f.follower_id == ^follower_id and f.following_id == ^following_id
  )
end

def are_friends?(user_id, friend_id) do
  Repo.exists?(
    from f in Friendship,
      where:
        ((f.user_id == ^user_id and f.friend_id == ^friend_id) or
           (f.user_id == ^friend_id and f.friend_id == ^user_id)) and
          f.status == "accepted"
  )
end
```

### Repo.aggregate

```elixir
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

def get_next_step_order(goal_id) do
  case Repo.aggregate(from(s in GoalStep, where: s.goal_id == ^goal_id), :max, :order) do
    nil -> 1
    max_order -> max_order + 1
  end
end

def get_followers_count(user_id) do
  Repo.aggregate(from(f in UserFollow, where: f.following_id == ^user_id), :count, :id)
end
```

## Preloading Patterns

### Pipeline Preloading

```elixir
def list_goals do
  from(g in Goal, where: is_nil(g.deleted_at))
  |> Repo.all()
  |> Repo.preload([:group, :user, :goal_steps])
end
```

### Inline Preloading

```elixir
from(f in Friendship,
  where: f.friend_id == ^user_id and f.status == "pending",
  preload: [:user]
)
|> Repo.all()
```

### Nested Preloading

```elixir
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
```

### Ordered Preloading with Query

```elixir
goals = Goals.list_goals()
|> Repo.preload([
  :group,
  :user,
  :goal_likes,
  :goal_subscriptions,
  :goal_steps,
  goal_posts: from(p in HeadsUp.Goals.GoalPost, order_by: [desc: p.inserted_at], preload: [:user])
])
```

### Manual Preload Replacement

```elixir
# Load goal posts separately with explicit ordering
goal_posts = from(p in HeadsUp.Goals.GoalPost,
  where: p.goal_id == ^goal.id,
  order_by: [desc: p.inserted_at],
  preload: [:user]
) |> Repo.all()

goal = Repo.preload(goal, [:group, :user, :goal_likes, :goal_subscriptions, :goal_steps])
goal = Map.put(goal, :goal_posts, goal_posts)
```

## Transaction Pattern

```elixir
# File: /lib/heads_up/activity_service.ex
def track_activity(user_id, activity_type, opts \\ []) do
  xp_change = Map.get(@xp_rewards, activity_type, 0)

  activity_attrs = %{
    user_id: user_id,
    activity_type: activity_type,
    xp_change: xp_change,
    # ...
  }

  Repo.transaction(fn ->
    # Create activity record
    {:ok, activity} =
      %UserActivity{}
      |> UserActivity.changeset(activity_attrs)
      |> Repo.insert()

    # Update user XP and level
    update_user_xp_and_level(user_id, xp_change)

    activity
  end)
end
```

### Ecto.Multi for Complex Transactions

```elixir
# File: /lib/heads_up/auth.ex
def update_user_password(user, password, attrs) do
  changeset =
    user
    |> Users.password_changeset(attrs)
    |> Users.validate_current_password(password)

  Ecto.Multi.new()
  |> Ecto.Multi.update(:user, changeset)
  |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
  |> Repo.transaction()
  |> case do
    {:ok, %{user: user}} -> {:ok, user}
    {:error, :user, changeset, _} -> {:error, changeset}
  end
end

def reset_user_password(user, attrs) do
  Ecto.Multi.new()
  |> Ecto.Multi.update(:user, Users.password_changeset(user, attrs))
  |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
  |> Repo.transaction()
  |> case do
    {:ok, %{user: user}} -> {:ok, user}
    {:error, :user, changeset, _} -> {:error, changeset}
  end
end
```

## Soft Delete Pattern

```elixir
# File: /lib/heads_up/goals.ex
def soft_delete_goal(%Goal{} = goal) do
  goal
  |> Goal.changeset(%{status: :deleted, deleted_at: DateTime.utc_now()})
  |> Repo.update()
end

def restore_goal(%Goal{} = goal) do
  goal
  |> Goal.changeset(%{status: :active, deleted_at: nil})
  |> Repo.update()
end

# All list queries exclude soft-deleted records
def list_goals do
  from(g in Goal, where: is_nil(g.deleted_at))
  |> Repo.all()
  |> Repo.preload([:group, :user, :goal_steps])
end

def list_deleted_goals_by_user(user_id) do
  from(g in Goal, where: g.user_id == ^user_id and not is_nil(g.deleted_at))
  |> Repo.all()
  |> Repo.preload([:group, :user])
end
```

## Data Transformation Pattern

```elixir
# File: /lib/heads_up/goals.ex
def add_social_counts(goals) do
  Enum.map(goals, fn goal ->
    like_count = length(goal.goal_likes)
    subscriber_count = length(goal.goal_subscriptions)

    goal
    |> Map.put(:like_count, like_count)
    |> Map.put(:subscriber_count, subscriber_count)
  end)
end
```

## Architectural Constraints

1. **Context Only**: Repo calls only in context modules or services
2. **No Raw SQL**: Use Ecto query DSL, avoid raw SQL when possible
3. **Explicit Preloading**: Preload associations explicitly, don't rely on lazy loading
4. **Soft Delete**: Use `deleted_at` timestamp pattern for reversible deletion
5. **Query Composition**: Build queries incrementally using Ecto.Query macros
