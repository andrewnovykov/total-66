# Ecto Schemas - Domain Patterns

## Overview

Ecto schemas in HeadsUp define the mapping between database tables and Elixir structs. They contain field definitions, associations, and changeset functions for validation. Schemas do not contain business logic - that belongs in contexts.

## Schema Files

| Schema Module | File Path | Table | Purpose |
|---------------|-----------|-------|---------|
| `HeadsUp.Users` | `/lib/heads_up/users.ex` | `users` | User accounts and profiles |
| `HeadsUp.Goal` | `/lib/heads_up/goal.ex` | `goals` | User goals |
| `HeadsUp.GoalStep` | `/lib/heads_up/goal_step.ex` | `goal_steps` | Goal breakdown steps |
| `HeadsUp.Goals.GoalPost` | `/lib/heads_up/goals/goal_post.ex` | `goal_posts` | Social posts on goals |
| `HeadsUp.GoalLike` | `/lib/heads_up/goal_like.ex` | `goal_likes` | Goal like relationships |
| `HeadsUp.GoalPostLike` | `/lib/heads_up/goal_post_like.ex` | `goal_post_likes` | Post like relationships |
| `HeadsUp.GoalSubscription` | `/lib/heads_up/goal_subscription.ex` | `goal_subscriptions` | Goal subscriptions |
| `HeadsUp.Group` | `/lib/heads_up/group.ex` | `groups` | Goal categories/groups |
| `HeadsUp.UserFollow` | `/lib/heads_up/user_follow.ex` | `user_follows` | Follow relationships |
| `HeadsUp.Friendship` | `/lib/heads_up/friendship.ex` | `friendships` | Friend relationships |
| `HeadsUp.UserActivity` | `/lib/heads_up/user_activity.ex` | `user_activities` | Activity tracking for XP |
| `HeadsUp.UserLevel` | `/lib/heads_up/user_level.ex` | `user_levels` | User level progression |
| `HeadsUp.Challenges.Challenge` | `/lib/heads_up/challenges/challenge.ex` | `challenges` | Challenge templates and instances |
| `HeadsUp.Challenges.ChallengeCategory` | `/lib/heads_up/challenges/challenge_category.ex` | `challenge_categories` | Challenge categories |
| `HeadsUp.Challenges.ChallengeParticipant` | `/lib/heads_up/challenges/challenge_participant.ex` | `challenge_participants` | User participation in challenges |
| `HeadsUp.Challenges.ChallengePhase` | `/lib/heads_up/challenges/challenge_phase.ex` | `challenge_phases` | Challenge phases with day ranges |
| `HeadsUp.Challenges.ChallengeStep` | `/lib/heads_up/challenges/challenge_step.ex` | `challenge_steps` | Steps within phases |
| `HeadsUp.Challenges.ChallengeStepProgress` | `/lib/heads_up/challenges/challenge_step_progress.ex` | `challenge_step_progress` | User progress on steps |
| `HeadsUp.Challenges.ChallengeTask` | `/lib/heads_up/challenges/challenge_task.ex` | `challenge_tasks` | Tasks within steps |
| `HeadsUp.Challenges.ChallengeTaskCompletion` | `/lib/heads_up/challenges/challenge_task_completion.ex` | `challenge_task_completions` | Task completion tracking |
| `HeadsUp.Challenges.DailyCheckIn` | `/lib/heads_up/challenges/daily_check_in.ex` | `daily_check_ins` | Daily mood check-ins |
| `HeadsUp.Challenges.CheckInLike` | `/lib/heads_up/challenges/check_in_like.ex` | `check_in_likes` | Likes on check-ins |
| `HeadsUp.Challenges.CheckInComment` | `/lib/heads_up/challenges/check_in_comment.ex` | `check_in_comments` | Comments on check-ins |

## Module Structure

### Standard Schema Pattern

```elixir
# File: /lib/heads_up/goal.ex
defmodule HeadsUp.Goal do
  use Ecto.Schema
  import Ecto.Changeset

  schema "goals" do
    # Field definitions
    field :title, :string
    field :description, :string
    # ...

    # Associations
    belongs_to :user, HeadsUp.Users
    has_many :goal_posts, HeadsUp.Goals.GoalPost

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(goal, attrs) do
    goal
    |> cast(attrs, [...])
    |> validate_required([...])
    # ...
  end
end
```

## Field Types

### Basic Fields

```elixir
# File: /lib/heads_up/goal.ex
schema "goals" do
  field :title, :string
  field :description, :string
  field :big_description, :string
  field :progress, :integer, default: 0
  field :image_path, :string
  field :failure_reason, :string
  field :is_frozen, :boolean, default: false

  timestamps(type: :utc_datetime)
end
```

### DateTime Fields

```elixir
# File: /lib/heads_up/goal.ex
field :target_date, :utc_datetime
field :failed_at, :utc_datetime
field :deleted_at, :utc_datetime

timestamps(type: :utc_datetime)
```

### Ecto.Enum Fields

```elixir
# File: /lib/heads_up/goal.ex
field :status, Ecto.Enum,
  values: [:active, :completed, :paused, :cancelled, :frozen, :failed, :deleted],
  default: :active

field :privacy, Ecto.Enum,
  values: [:public, :private, :friends],
  default: :public
```

### Virtual Fields

```elixir
# File: /lib/heads_up/users.ex
field :password, :string, virtual: true, redact: true
field :current_password, :string, virtual: true, redact: true
```

### Map Fields

```elixir
# File: /lib/heads_up/user_activity.ex
field :metadata, :map, default: %{}
```

### Module Attributes for Validation

```elixir
# File: /lib/heads_up/user_activity.ex
@activity_types [
  "goal_created",
  "goal_completed",
  "goal_failed",
  "goal_frozen",
  "goal_deleted",
  "goal_updated",
  "post_created",
  "post_liked",
  "post_received_like",
  "user_followed",
  "user_received_follow",
  "friend_request_sent",
  "friend_request_accepted",
  "daily_login",
  "goal_step_completed"
]
```

## Association Patterns

### belongs_to

```elixir
# File: /lib/heads_up/goal.ex
belongs_to :group, HeadsUp.Group
belongs_to :user, HeadsUp.Users
```

### has_many

```elixir
# File: /lib/heads_up/goal.ex
has_many :goal_likes, HeadsUp.GoalLike
has_many :goal_subscriptions, HeadsUp.GoalSubscription
has_many :goal_posts, HeadsUp.Goals.GoalPost
has_many :goal_steps, HeadsUp.GoalStep, preload_order: [asc: :order]
```

### has_many :through

```elixir
# File: /lib/heads_up/goal.ex
has_many :likes, through: [:goal_likes, :user]
has_many :subscribers, through: [:goal_subscriptions, :user]
```

### has_one

```elixir
# File: /lib/heads_up/users.ex
has_one :user_level, HeadsUp.UserLevel, foreign_key: :user_id
```

### Self-Referential Associations

```elixir
# File: /lib/heads_up/users.ex
# Follow relationships
has_many :follower_relationships, HeadsUp.UserFollow, foreign_key: :following_id
has_many :followers, through: [:follower_relationships, :follower]

has_many :following_relationships, HeadsUp.UserFollow, foreign_key: :follower_id
has_many :following, through: [:following_relationships, :following]

# Friendship relationships
has_many :sent_friend_requests, HeadsUp.Friendship, foreign_key: :user_id
has_many :received_friend_requests, HeadsUp.Friendship, foreign_key: :friend_id
```

## Changeset Pattern

### Basic Changeset

```elixir
# File: /lib/heads_up/goal.ex
@doc false
def changeset(goal, attrs) do
  goal
  |> cast(attrs, [:title, :description, :big_description, :status, :privacy,
                  :target_date, :progress, :image_path, :failure_reason,
                  :failed_at, :deleted_at, :is_frozen, :group_id, :user_id])
  |> validate_required([:title, :group_id, :user_id])
  |> validate_inclusion(:progress, 0..100)
  |> validate_failure_reason()
  |> foreign_key_constraint(:group_id)
  |> foreign_key_constraint(:user_id)
end
```

### Multiple Changesets for Different Purposes

```elixir
# File: /lib/heads_up/users.ex

# Basic changeset for updates
def changeset(user, attrs) do
  user
  |> cast(attrs, [:user_name, :name, :bio, :about, :level, :image_path,
                  :goal_amount, :subscription_type, :privacy, :role, :xp])
  |> validate_required([:user_name, :name])
  |> validate_inclusion(:subscription_type, ["free", "pro_3", "pro_5", "unlimited"])
  |> validate_inclusion(:privacy, ["public", "private", "friends_only"])
  |> validate_inclusion(:role, ["user", "admin"])
end

# Registration changeset with password
def registration_changeset(user, attrs, opts \\ []) do
  user
  |> cast(attrs, [:email, :password, :user_name, :name, :bio, :about,
                  :level, :image_path, :goal_amount])
  |> validate_email(opts)
  |> validate_password(opts)
  |> validate_required([:user_name, :name])
  |> validate_length(:user_name, min: 3, max: 20)
  |> validate_format(:user_name, ~r/^[a-zA-Z0-9_]+$/,
    message: "can only contain letters, numbers, and underscores"
  )
  |> unsafe_validate_unique(:user_name, HeadsUp.Repo)
  |> unique_constraint(:user_name)
end

# Email changeset
def email_changeset(user, attrs, opts \\ []) do
  user
  |> cast(attrs, [:email])
  |> validate_email(opts)
  |> case do
    %{changes: %{email: _}} = changeset -> changeset
    %{} = changeset -> add_error(changeset, :email, "did not change")
  end
end

# Password changeset
def password_changeset(user, attrs, opts \\ []) do
  user
  |> cast(attrs, [:password])
  |> validate_confirmation(:password, message: "does not match password")
  |> validate_password(opts)
end

# Confirm changeset
def confirm_changeset(user) do
  now = DateTime.utc_now() |> DateTime.truncate(:second)
  change(user, confirmed_at: now)
end
```

## Validation Patterns

### Required Fields

```elixir
|> validate_required([:title, :group_id, :user_id])
```

### Length Validation

```elixir
|> validate_length(:user_name, min: 3, max: 20)
|> validate_length(:password, min: 12, max: 72)
|> validate_length(:email, max: 160)
```

### Format Validation

```elixir
|> validate_format(:user_name, ~r/^[a-zA-Z0-9_]+$/,
  message: "can only contain letters, numbers, and underscores"
)
|> validate_format(:email, ~r/^[^\s]+@[^\s]+$/,
  message: "must have the @ sign and no spaces"
)
```

### Inclusion Validation

```elixir
|> validate_inclusion(:progress, 0..100)
|> validate_inclusion(:subscription_type, ["free", "pro_3", "pro_5", "unlimited"])
|> validate_inclusion(:privacy, ["public", "private", "friends_only"])
|> validate_inclusion(:status, ["pending", "accepted", "declined", "blocked"])
|> validate_inclusion(:activity_type, @activity_types)
```

### Unique Constraints

```elixir
|> unsafe_validate_unique(:user_name, HeadsUp.Repo)
|> unique_constraint(:user_name)
|> unsafe_validate_unique(:email, HeadsUp.Repo)
|> unique_constraint(:email)
|> unique_constraint([:follower_id, :following_id])
|> unique_constraint([:user_id, :friend_id])
```

### Foreign Key Constraints

```elixir
|> foreign_key_constraint(:user_id)
|> foreign_key_constraint(:goal_id)
|> foreign_key_constraint(:group_id)
|> foreign_key_constraint(:follower_id)
|> foreign_key_constraint(:following_id)
```

## Custom Validation Pattern

### Conditional Validation

```elixir
# File: /lib/heads_up/goal.ex
defp validate_failure_reason(changeset) do
  failure_reason = get_field(changeset, :failure_reason)
  failed_at = get_field(changeset, :failed_at)
  status = get_field(changeset, :status)

  case {status, failed_at, failure_reason} do
    {:failed, _, nil} ->
      add_error(changeset, :failure_reason, "is required when goal is marked as failed")
    {:failed, _, ""} ->
      add_error(changeset, :failure_reason, "is required when goal is marked as failed")
    {_, date, nil} when not is_nil(date) ->
      add_error(changeset, :failure_reason, "is required when goal is marked as failed")
    {_, date, ""} when not is_nil(date) ->
      add_error(changeset, :failure_reason, "is required when goal is marked as failed")
    _ ->
      changeset
  end
end
```

### Self-Reference Validation

```elixir
# File: /lib/heads_up/user_follow.ex
defp validate_not_self_follow(changeset) do
  follower_id = get_field(changeset, :follower_id)
  following_id = get_field(changeset, :following_id)

  if follower_id == following_id do
    add_error(changeset, :following_id, "cannot follow yourself")
  else
    changeset
  end
end
```

```elixir
# File: /lib/heads_up/friendship.ex
defp validate_not_self_friend(changeset) do
  user_id = get_field(changeset, :user_id)
  friend_id = get_field(changeset, :friend_id)

  if user_id && friend_id && user_id == friend_id do
    add_error(changeset, :friend_id, "cannot be friends with yourself")
  else
    changeset
  end
end
```

## Password Hashing Pattern

```elixir
# File: /lib/heads_up/users.ex
defp maybe_hash_password(changeset, opts) do
  hash_password? = Keyword.get(opts, :hash_password, true)
  password = get_change(changeset, :password)

  if hash_password? && password && changeset.valid? do
    changeset
    |> validate_length(:password, max: 72, count: :bytes)
    |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
    |> delete_change(:password)
  else
    changeset
  end
end
```

## Password Verification

```elixir
# File: /lib/heads_up/users.ex
def valid_password?(%HeadsUp.Users{hashed_password: hashed_password}, password)
    when is_binary(hashed_password) and byte_size(password) > 0 do
  Bcrypt.verify_pass(password, hashed_password)
end

def valid_password?(_, _) do
  Bcrypt.no_user_verify()
  false
end
```

## Complete Schema Examples

### Goal Schema

```elixir
# File: /lib/heads_up/goal.ex
defmodule HeadsUp.Goal do
  use Ecto.Schema
  import Ecto.Changeset

  schema "goals" do
    field :title, :string
    field :description, :string
    field :big_description, :string
    field :status, Ecto.Enum,
      values: [:active, :completed, :paused, :cancelled, :frozen, :failed, :deleted],
      default: :active
    field :privacy, Ecto.Enum, values: [:public, :private, :friends], default: :public
    field :target_date, :utc_datetime
    field :progress, :integer, default: 0
    field :image_path, :string
    field :failure_reason, :string
    field :failed_at, :utc_datetime
    field :deleted_at, :utc_datetime
    field :is_frozen, :boolean, default: false

    belongs_to :group, HeadsUp.Group
    belongs_to :user, HeadsUp.Users

    has_many :goal_likes, HeadsUp.GoalLike
    has_many :goal_subscriptions, HeadsUp.GoalSubscription
    has_many :goal_posts, HeadsUp.Goals.GoalPost
    has_many :goal_steps, HeadsUp.GoalStep, preload_order: [asc: :order]
    has_many :likes, through: [:goal_likes, :user]
    has_many :subscribers, through: [:goal_subscriptions, :user]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(goal, attrs) do
    goal
    |> cast(attrs, [:title, :description, :big_description, :status, :privacy,
                    :target_date, :progress, :image_path, :failure_reason,
                    :failed_at, :deleted_at, :is_frozen, :group_id, :user_id])
    |> validate_required([:title, :group_id, :user_id])
    |> validate_inclusion(:progress, 0..100)
    |> validate_failure_reason()
    |> foreign_key_constraint(:group_id)
    |> foreign_key_constraint(:user_id)
  end

  defp validate_failure_reason(changeset) do
    # ... custom validation
  end
end
```

### UserActivity Schema

```elixir
# File: /lib/heads_up/user_activity.ex
defmodule HeadsUp.UserActivity do
  use Ecto.Schema
  import Ecto.Changeset

  @activity_types [
    "goal_created", "goal_completed", "goal_failed", "goal_frozen",
    "goal_deleted", "goal_updated", "post_created", "post_liked",
    "post_received_like", "user_followed", "user_received_follow",
    "friend_request_sent", "friend_request_accepted", "daily_login",
    "goal_step_completed"
  ]

  schema "user_activities" do
    field :activity_type, :string
    field :xp_change, :integer, default: 0
    field :description, :string
    field :metadata, :map, default: %{}

    belongs_to :user, HeadsUp.Users
    belongs_to :goal, HeadsUp.Goal
    belongs_to :post, HeadsUp.Goals.GoalPost
    field :like_id, :integer
    field :follow_id, :integer

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(user_activity, attrs) do
    user_activity
    |> cast(attrs, [:activity_type, :xp_change, :description, :metadata,
                    :user_id, :goal_id, :post_id, :like_id, :follow_id])
    |> validate_required([:activity_type, :user_id])
    |> validate_inclusion(:activity_type, @activity_types)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:goal_id)
    |> foreign_key_constraint(:post_id)
  end

  def activity_types, do: @activity_types
end
```

## Architectural Constraints

1. **No Business Logic**: Schemas contain only data mapping and validation
2. **Immutable Validation**: Changesets validate but don't have side effects
3. **Virtual Fields**: Use `virtual: true` for non-persisted fields
4. **UTC Timestamps**: Use `timestamps(type: :utc_datetime)`
5. **Ecto.Enum**: Use for status fields with defined values
6. **Changeset Functions**: Every schema has a `changeset/2` function
