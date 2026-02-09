# Phoenix Contexts - Domain Patterns

## Overview

Phoenix contexts in HeadsUp provide bounded domain logic and encapsulate all database operations. The application follows the "context owns schema" pattern where each schema belongs to a single context that manages its lifecycle.

## Module Structure

### Standard Context Pattern

Contexts import Ecto.Query and alias the Repo and related schemas:

```elixir
# File: /lib/heads_up/goals.ex
defmodule HeadsUp.Goals do
  import Ecto.Query, warn: false
  alias HeadsUp.Repo
  alias HeadsUp.Goal
  alias HeadsUp.GoalStep
  alias HeadsUp.GoalLike
  alias HeadsUp.GoalSubscription
  alias HeadsUp.Goals.GoalPost
  alias HeadsUp.GoalPostLike
  alias HeadsUp.ActivityService
  # ...
end
```

```elixir
# File: /lib/heads_up/accounts.ex
defmodule HeadsUp.Accounts do
  alias HeadsUp.Repo
  alias HeadsUp.{Users, UserFollow, Friendship, ActivityService}
  import Ecto.Query
  # ...
end
```

```elixir
# File: /lib/heads_up/groups.ex
defmodule HeadsUp.Groups do
  import Ecto.Query, warn: false
  alias HeadsUp.Repo
  alias HeadsUp.Group
  # ...
end
```

## Context Files

| Context Module | File Path | Primary Responsibility |
|----------------|-----------|----------------------|
| `HeadsUp.Goals` | `/lib/heads_up/goals.ex` | Goal CRUD, steps, posts, likes, subscriptions |
| `HeadsUp.Accounts` | `/lib/heads_up/accounts.ex` | User relationships, follows, friendships |
| `HeadsUp.Auth` | `/lib/heads_up/auth.ex` | User authentication, registration, tokens |
| `HeadsUp.Groups` | `/lib/heads_up/groups.ex` | Goal categories/groups management |
| `HeadsUp.Challenges` | `/lib/heads_up/challenges.ex` | Challenge CRUD, templates, participants, check-ins, phases/steps/tasks |
| `HeadsUp.BusinessRules` | `/lib/heads_up/business_rules.ex` | Role-aware active item limits (admin=unlimited, free=3, pro=10) |
| `HeadsUp.FeedService` | `/lib/heads_up/feed_service.ex` | Aggregated activity feed for home page |

## Naming Conventions

### Function Naming

1. **List functions**: `list_*` - Returns multiple records
   ```elixir
   def list_goals do
   def list_goals_by_user(user_id) do
   def list_goals_by_group(group_id, opts \\ []) do
   def list_public_goals_by_group(group_id) do
   def list_deleted_goals_by_user(user_id) do
   ```

2. **Get functions**: `get_*` and `get_*!` - Returns single record
   ```elixir
   def get_goal(id) do
     Repo.get(Goal, id)
   end

   def get_goal!(id) do
     Repo.get!(Goal, id)
     |> Repo.preload([...])
   end
   ```

3. **Create functions**: `create_*`
   ```elixir
   def create_goal(attrs \\ %{}) do
   def create_goal_post(attrs \\ %{}) do
   def create_goal_step(attrs \\ %{}) do
   ```

4. **Update functions**: `update_*`
   ```elixir
   def update_goal(%Goal{} = goal, attrs) do
   def update_goal_step(%GoalStep{} = step, attrs) do
   ```

5. **Delete functions**: `delete_*` and `soft_delete_*`
   ```elixir
   def delete_goal(%Goal{} = goal) do
   def soft_delete_goal(%Goal{} = goal) do
   ```

6. **Ownership functions**: `*_with_ownership` - Validates user owns resource
   ```elixir
   def update_goal_with_ownership(%Goal{} = goal, attrs, user_id) do
   def soft_delete_goal_with_ownership(%Goal{} = goal, user_id) do
   def create_goal_post_with_ownership(attrs, user_id) do
   def freeze_goal_with_ownership(%Goal{} = goal, user_id) do
   ```

7. **Change functions**: `change_*` - Returns changeset for forms
   ```elixir
   def change_goal(%Goal{} = goal, attrs \\ %{}) do
     Goal.changeset(goal, attrs)
   end
   ```

8. **Boolean query functions**: `*?` suffix
   ```elixir
   def user_liked_goal?(goal_id, user_id) do
   def user_subscribed_to_goal?(goal_id, user_id) do
   def is_following?(follower_id, following_id) do
   def are_friends?(user_id, friend_id) do
   ```

## Ownership Validation Pattern

The `*_with_ownership` pattern is used throughout HeadsUp to enforce resource ownership:

```elixir
# File: /lib/heads_up/goals.ex
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
          # Track activity
          ActivityService.track_activity(user_id, "goal_updated",
            goal_id: goal.id,
            description: "Updated goal: #{goal.title}"
          )
          {:ok, updated_goal}

        error ->
          error
      end
  end
end
```

### Ownership Through Association

For nested resources (like GoalStep), ownership is checked through the parent:

```elixir
# File: /lib/heads_up/goals.ex
def update_goal_step_with_ownership(%GoalStep{} = step, attrs, user_id) do
  step = Repo.preload(step, :goal)

  if step.goal.user_id == user_id do
    update_goal_step(step, attrs)
  else
    {:error, :unauthorized}
  end
end
```

## Error Tuple Pattern

All context functions return `{:ok, result}` or `{:error, reason}` tuples:

```elixir
# Success cases
{:ok, goal}
{:ok, _deleted_goal}
{:ok, :removed}

# Error cases
{:error, :unauthorized}
{:error, :not_found}
{:error, :frozen}
{:error, :failed}
{:error, :cannot_like_own_goal}
{:error, :cannot_subscribe_to_own_goal}
{:error, :access_denied}
{:error, :user_not_found}
{:error, :cannot_follow_self}
{:error, :user_is_private}
{:error, :must_be_friends}
{:error, :friendship_already_exists}
{:error, :request_not_found}
{:error, :request_not_pending}
{:error, %Ecto.Changeset{}}
```

## Query Composition Pattern

Queries are built using Ecto.Query macros with conditional composition:

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

## Preloading Pattern

Preloading is done explicitly in context functions, not in LiveViews:

```elixir
# File: /lib/heads_up/goals.ex
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

def list_goals do
  from(g in Goal, where: is_nil(g.deleted_at))
  |> Repo.all()
  |> Repo.preload([:group, :user, :goal_steps])
end
```

## Self-Interaction Prevention Pattern

Users cannot like or subscribe to their own content:

```elixir
# File: /lib/heads_up/goals.ex
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

def like_post(post_id, user_id) do
  post = Repo.get!(GoalPost, post_id) |> Repo.preload(:user)

  if post.user_id == user_id do
    {:error, :cannot_like_own_post}
  else
    # ... insert like
  end
end
```

## Privacy-Aware Operations

Social operations respect privacy settings:

```elixir
# File: /lib/heads_up/accounts.ex
def follow_user(follower_id, following_id) do
  follower = Repo.get(Users, follower_id)
  following = Repo.get(Users, following_id)

  cond do
    is_nil(follower) or is_nil(following) ->
      {:error, :user_not_found}

    follower_id == following_id ->
      {:error, :cannot_follow_self}

    following.privacy == "private" ->
      {:error, :user_is_private}

    following.privacy == "friends_only" and not are_friends?(follower_id, following_id) ->
      {:error, :must_be_friends}

    true ->
      # ... create follow relationship
  end
end
```

## Aggregation Pattern

Use `Repo.aggregate` for counts:

```elixir
# File: /lib/heads_up/goals.ex
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
```

```elixir
# File: /lib/heads_up/accounts.ex
def get_followers_count(user_id) do
  Repo.aggregate(from(f in UserFollow, where: f.following_id == ^user_id), :count, :id)
end
```

## Activity Tracking Integration

Contexts integrate with ActivityService for gamification:

```elixir
# File: /lib/heads_up/goals.ex
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

## Soft Delete Pattern

Goals use soft deletion with `deleted_at` timestamp:

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

# List queries exclude soft-deleted records
def list_goals do
  from(g in Goal, where: is_nil(g.deleted_at))
  |> Repo.all()
  |> Repo.preload([:group, :user, :goal_steps])
end
```

## Architectural Constraints

1. **No Repo in Web Layer**: Repo is never called directly from LiveViews or controllers
2. **Context Owns Schema**: Each schema belongs to a single context
3. **Error Tuples**: All functions return `{:ok, result}` or `{:error, reason}`
4. **Explicit Preloading**: Related data is preloaded through context functions
5. **Ownership Validation**: Mutable operations validate user ownership
