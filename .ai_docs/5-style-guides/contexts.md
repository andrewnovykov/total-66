# Context Module Style Guide

This style guide documents the patterns and conventions used in HeadsUp context modules.

## Module Structure

### Module Declaration and Imports

```elixir
defmodule HeadsUp.Goals do
  import Ecto.Query, warn: false
  alias HeadsUp.Repo
  alias HeadsUp.Goal
  alias HeadsUp.GoalStep
  # ... other aliases
```

**Pattern**: Import `Ecto.Query` with `warn: false` at the top, then alias `Repo` and all related schemas.

### Alias Grouping

Context modules use grouped aliases for related schemas:

```elixir
alias HeadsUp.{Users, UserFollow, Friendship, ActivityService}
```

## Function Naming Conventions

### CRUD Operations

| Pattern | Example | Description |
|---------|---------|-------------|
| `list_*` | `list_goals`, `list_users` | Returns all records |
| `list_*_by_*` | `list_goals_by_user(user_id)` | Filtered list queries |
| `get_*` | `get_goal(id)` | Returns record or nil |
| `get_*!` | `get_goal!(id)` | Returns record or raises |
| `create_*` | `create_goal(attrs)` | Creates new record |
| `update_*` | `update_goal(goal, attrs)` | Updates existing record |
| `delete_*` | `delete_goal(goal)` | Hard deletes record |
| `soft_delete_*` | `soft_delete_goal(goal)` | Sets deleted_at timestamp |
| `change_*` | `change_goal(goal, attrs)` | Returns changeset for forms |

### Ownership-Protected Operations

**Key Pattern**: Functions that require ownership validation use `_with_ownership` suffix:

```elixir
def update_goal_with_ownership(%Goal{} = goal, attrs, user_id) do
  cond do
    goal.user_id != user_id ->
      {:error, :unauthorized}
    goal.status == :failed ->
      {:error, :failed}
    goal.is_frozen or goal.status == :frozen ->
      {:error, :frozen}
    true ->
      update_goal(goal, attrs)
  end
end
```

**Pattern**: These functions:
1. Take the resource as first argument
2. Take attributes as second argument
3. Take `user_id` as the last argument
4. Return `{:error, :unauthorized}` for permission failures
5. Return `{:error, :specific_reason}` for business logic failures

### Boolean Query Functions

Pattern: `{noun}_{verb}?` returning boolean:

```elixir
def user_liked_goal?(goal_id, user_id) do
  Repo.exists?(from(gl in GoalLike, where: gl.goal_id == ^goal_id and gl.user_id == ^user_id))
end

def user_subscribed_to_goal?(goal_id, user_id)
def is_following?(follower_id, following_id)
def are_friends?(user_id, friend_id)
def friendship_exists?(user_id, friend_id)
```

### Toggle Operations

Pattern: `toggle_*` for flip operations:

```elixir
def toggle_goal_step_completion(%GoalStep{} = step) do
  update_goal_step(step, %{completed: !step.completed})
end

def toggle_goal_step_completion_with_ownership(%GoalStep{} = step, user_id)
```

## Query Patterns

### Soft Delete Filtering

**Pattern**: All list queries filter out soft-deleted records:

```elixir
def list_goals do
  from(g in Goal, where: is_nil(g.deleted_at))
  |> Repo.all()
  |> Repo.preload([:group, :user, :goal_steps])
end
```

### Optional Filtering with Keywords

```elixir
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

### Preloading Patterns

**Pattern**: Chain preloads after `Repo.all()`:

```elixir
from(g in Goal, where: g.group_id == ^group_id)
|> Repo.all()
|> Repo.preload([:group, :user, :goal_likes, :goal_subscriptions])
```

**Pattern**: Nested preloads for associations:

```elixir
Repo.preload([
  :group,
  :user,
  :goal_likes,
  :goal_subscriptions,
  :goal_steps,
  goal_posts: [:user, :step]
])
```

## Error Handling Patterns

### Standardized Error Tuples

```elixir
{:ok, resource}           # Success
{:error, :unauthorized}   # Permission denied
{:error, :not_found}      # Resource not found
{:error, :frozen}         # Resource is frozen
{:error, :failed}         # Resource in failed state
{:error, changeset}       # Validation errors
{:error, :cannot_like_own_goal}   # Business logic constraint
{:error, :cannot_subscribe_to_own_goal}
{:error, :user_not_found}
{:error, :cannot_follow_self}
{:error, :user_is_private}
{:error, :must_be_friends}
```

### Self-Action Prevention

**Pattern**: Prevent users from interacting with their own content:

```elixir
def like_goal(goal_id, user_id) do
  goal = get_goal!(goal_id)

  if goal.user_id == user_id do
    {:error, :cannot_like_own_goal}
  else
    %GoalLike{}
    |> GoalLike.changeset(%{goal_id: goal_id, user_id: user_id})
    |> Repo.insert()
  end
end
```

### Privacy-Based Access Control

```elixir
def subscribe_to_goal(goal_id, user_id) do
  goal = get_goal!(goal_id)

  cond do
    goal.user_id == user_id ->
      {:error, :cannot_subscribe_to_own_goal}
    goal.privacy == :private ->
      {:error, :access_denied}
    goal.privacy == :friends ->
      {:error, :access_denied}  # TODO: Check friendship status
    true ->
      # Allow subscription
  end
end
```

## Activity Tracking Integration

**Pattern**: Track activities after successful operations:

```elixir
def create_goal(attrs \\ %{}) do
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
```

## Aggregation Functions

### Count Functions

```elixir
def goal_counts(group_id) do
  total = Repo.aggregate(from(g in Goal, where: g.group_id == ^group_id), :count, :id)
  active = Repo.aggregate(
    from(g in Goal, where: g.group_id == ^group_id and g.status == :active),
    :count,
    :id
  )
  %{total_goal_amount: total, active_goal_amount: active}
end

def get_followers_count(user_id) do
  Repo.aggregate(from(f in UserFollow, where: f.following_id == ^user_id), :count, :id)
end
```

### Next Value Calculation

```elixir
def get_next_step_order(goal_id) do
  case Repo.aggregate(from(s in GoalStep, where: s.goal_id == ^goal_id), :max, :order) do
    nil -> 1
    max_order -> max_order + 1
  end
end
```

## Social Counts Enhancement

**Pattern**: Add computed fields to loaded records:

```elixir
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

## Bidirectional Relationship Queries

**Pattern**: Query both directions for symmetric relationships (friendships):

```elixir
def are_friends?(user_id, friend_id) do
  Repo.exists?(
    from f in Friendship,
      where:
        ((f.user_id == ^user_id and f.friend_id == ^friend_id) or
           (f.user_id == ^friend_id and f.friend_id == ^user_id)) and
          f.status == "accepted"
  )
end

def list_friends(user_id) do
  from(f in Friendship,
    where: (f.user_id == ^user_id or f.friend_id == ^user_id) and f.status == "accepted",
    preload: [:user, :friend]
  )
  |> Repo.all()
  |> Enum.map(fn friendship ->
    if friendship.user_id == user_id do
      friendship.friend
    else
      friendship.user
    end
  end)
end
```

## Module Attributes for Configuration

**Pattern**: Use module attributes for domain-specific configuration (see ActivityService):

```elixir
@level_thresholds %{
  1 => {0, 100, "Seastar"},
  2 => {100, 250, "Seastar"},
  # ...
}

@xp_rewards %{
  "goal_created" => 50,
  "goal_completed" => 1000,
  # ...
}
```
