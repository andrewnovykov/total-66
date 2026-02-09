# Schema Module Style Guide

This style guide documents the patterns and conventions used in HeadsUp Ecto schemas.

## Module Structure

### Standard Schema Declaration

```elixir
defmodule HeadsUp.Goal do
  use Ecto.Schema
  import Ecto.Changeset

  schema "goals" do
    # Fields
    # Associations
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(goal, attrs) do
    # Changeset logic
  end
end
```

**Pattern**: Always use `@doc false` for the main changeset function unless it has specific documentation.

## Naming Conventions

### Schema Module Names

| Pattern | Example |
|---------|---------|
| Primary entities | `HeadsUp.Goal`, `HeadsUp.Users` |
| Join tables | `HeadsUp.GoalLike`, `HeadsUp.UserFollow` |
| Nested schemas | `HeadsUp.Goals.GoalPost`, `HeadsUp.Auth.UserToken` |

**Note**: User schema is named `HeadsUp.Users` (plural) due to Phoenix auth generator conventions.

## Field Definitions

### Ecto.Enum Usage

```elixir
field :status, Ecto.Enum,
  values: [:active, :completed, :paused, :cancelled, :frozen, :failed, :deleted],
  default: :active

field :privacy, Ecto.Enum,
  values: [:public, :private, :friends],
  default: :public

field :post_type, Ecto.Enum,
  values: [:update, :milestone, :achievement, :challenge, :motivation],
  default: :update
```

**Pattern**: Use `Ecto.Enum` for typed string fields with defined values.

### String Status Fields (Alternative)

```elixir
# In Friendship schema - uses string for compatibility
field :status, :string, default: "pending"  # pending, accepted, declined, blocked
```

**Pattern**: Some schemas use string status with validation instead of Ecto.Enum.

### Virtual Fields

```elixir
# Authentication-related virtual fields
field :password, :string, virtual: true, redact: true
field :current_password, :string, virtual: true, redact: true
```

**Pattern**: Use `virtual: true` for fields not stored in database, `redact: true` for sensitive data.

### Default Values

```elixir
field :progress, :integer, default: 0
field :xp, :integer, default: 0
field :level, :integer, default: 1
field :is_frozen, :boolean, default: false
field :privacy, :string, default: "public"
field :subscription_type, :string, default: "free"
field :role, :string, default: "user"
```

**Pattern**: Always provide sensible defaults for non-nullable fields.

### Soft Delete Fields

```elixir
field :deleted_at, :utc_datetime
field :failure_reason, :string
field :failed_at, :utc_datetime
```

**Pattern**: Use nullable `_at` timestamp fields for soft deletes and state transitions.

## Timestamps Configuration

### Standard UTC Timestamps

```elixir
timestamps(type: :utc_datetime)
```

### Insert-Only Timestamps

```elixir
# For activity logs - no update tracking needed
timestamps(type: :utc_datetime, updated_at: false)
```

### Legacy Timestamps (Non-UTC)

```elixir
# Some schemas use default timestamps without UTC
timestamps()
```

## Association Patterns

### Belongs To

```elixir
belongs_to :user, HeadsUp.Users
belongs_to :goal, HeadsUp.Goal
belongs_to :group, HeadsUp.Group
```

### Has Many

```elixir
has_many :goals, HeadsUp.Goal, foreign_key: :user_id
has_many :goal_likes, HeadsUp.GoalLike
has_many :goal_posts, HeadsUp.Goals.GoalPost
```

### Has Many with Preload Order

```elixir
has_many :goal_steps, HeadsUp.GoalStep, preload_order: [asc: :order]
```

### Has Many Through (Virtual Associations)

```elixir
has_many :likes, through: [:goal_likes, :user]
has_many :subscribers, through: [:goal_subscriptions, :user]
has_many :followers, through: [:follower_relationships, :follower]
has_many :following, through: [:following_relationships, :following]
```

### Has Many with Custom Foreign Key

```elixir
has_many :follower_relationships, HeadsUp.UserFollow, foreign_key: :following_id
has_many :following_relationships, HeadsUp.UserFollow, foreign_key: :follower_id
has_many :goal_post_likes, HeadsUp.GoalPostLike, foreign_key: :goal_post_id
```

### Self-Referential Associations

```elixir
# Group hierarchies
belongs_to :parent, __MODULE__, foreign_key: :parent_id
has_many :subcategories, __MODULE__, foreign_key: :parent_id
```

### Has One

```elixir
has_one :user_level, HeadsUp.UserLevel, foreign_key: :user_id
```

## Changeset Patterns

### Standard Changeset Structure

```elixir
def changeset(goal, attrs) do
  goal
  |> cast(attrs, [:title, :description, :status, :privacy, ...])
  |> validate_required([:title, :group_id, :user_id])
  |> validate_inclusion(:progress, 0..100)
  |> custom_validation()
  |> foreign_key_constraint(:group_id)
  |> foreign_key_constraint(:user_id)
end
```

**Order of operations**:
1. `cast` - Extract permitted fields
2. `validate_required` - Required field validation
3. `validate_*` - Field-specific validations
4. Custom validations
5. `foreign_key_constraint` - Database constraints

### Multiple Changeset Functions

```elixir
# Users schema - multiple specialized changesets

def changeset(user, attrs)                    # Basic profile updates
def registration_changeset(user, attrs, opts) # New user registration
def email_changeset(user, attrs, opts)        # Email changes
def password_changeset(user, attrs, opts)     # Password changes
def confirm_changeset(user)                   # Email confirmation
```

### Changeset Options Pattern

```elixir
def registration_changeset(user, attrs, opts \\ []) do
  user
  |> cast(attrs, [:email, :password, :user_name, :name, ...])
  |> validate_email(opts)
  |> validate_password(opts)
  |> validate_required([:user_name, :name])
end

defp validate_password(changeset, opts) do
  changeset
  |> validate_required([:password])
  |> validate_length(:password, min: 12, max: 72)
  |> maybe_hash_password(opts)
end

defp maybe_hash_password(changeset, opts) do
  hash_password? = Keyword.get(opts, :hash_password, true)
  password = get_change(changeset, :password)

  if hash_password? && password && changeset.valid? do
    changeset
    |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
    |> delete_change(:password)
  else
    changeset
  end
end
```

**Pattern**: Use keyword `opts` for conditional processing (useful for LiveView form validation vs actual saves).

## Custom Validations

### Self-Reference Prevention

```elixir
defp validate_not_self_follow(changeset) do
  follower_id = get_field(changeset, :follower_id)
  following_id = get_field(changeset, :following_id)

  if follower_id == following_id do
    add_error(changeset, :following_id, "cannot follow yourself")
  else
    changeset
  end
end

defp validate_not_self_friend(changeset) do
  user_id = get_field(changeset, :user_id)
  friend_id = get_field(changeset, :friend_id)

  if user_id && friend_id && user_id == friend_id do
    add_error(changeset, :friend_id, "cannot be friends with yourself")
  else
    changeset
  end
end

defp validate_not_self_parent(changeset) do
  parent_id = get_field(changeset, :parent_id)
  group_id = get_field(changeset, :id)

  if parent_id && group_id && parent_id == group_id do
    add_error(changeset, :parent_id, "cannot be parent of itself")
  else
    changeset
  end
end
```

**Pattern**: Name custom validators `validate_not_self_*` for self-reference prevention.

### Conditional Required Fields

```elixir
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
    _ ->
      changeset
  end
end
```

**Pattern**: Use tuple pattern matching for complex conditional validations.

## Validation Types

### Common Validations

```elixir
validate_required([:title, :group_id, :user_id])
validate_length(:title, min: 1, max: 255)
validate_length(:password, min: 12, max: 72)
validate_length(:user_name, min: 3, max: 20)
validate_inclusion(:progress, 0..100)
validate_inclusion(:subscription_type, ["free", "pro_3", "pro_5", "unlimited"])
validate_inclusion(:privacy, ["public", "private", "friends_only"])
validate_inclusion(:status, ["pending", "accepted", "declined", "blocked"])
validate_inclusion(:activity_type, @activity_types)
validate_number(:level, greater_than: 0, less_than_or_equal_to: 40)
validate_number(:xp, greater_than_or_equal_to: 0)
validate_confirmation(:password, message: "does not match password")
validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
validate_format(:user_name, ~r/^[a-zA-Z0-9_]+$/, message: "can only contain letters, numbers, and underscores")
```

### Uniqueness Validations

```elixir
# Unsafe validation (check before insert, race condition possible)
|> unsafe_validate_unique(:email, HeadsUp.Repo)
|> unsafe_validate_unique(:user_name, HeadsUp.Repo)

# Constraint (database-enforced)
|> unique_constraint(:email)
|> unique_constraint(:user_name)
|> unique_constraint([:goal_id, :user_id])
|> unique_constraint([:goal_post_id, :user_id])
|> unique_constraint([:follower_id, :following_id])
|> unique_constraint([:user_id, :friend_id])
```

**Pattern**: Use both `unsafe_validate_unique` (for better UX) and `unique_constraint` (for data integrity).

### Foreign Key Constraints

```elixir
|> foreign_key_constraint(:user_id)
|> foreign_key_constraint(:goal_id)
|> foreign_key_constraint(:group_id)
|> foreign_key_constraint(:parent_id)
|> foreign_key_constraint(:goal_post_id)
|> foreign_key_constraint(:follower_id)
|> foreign_key_constraint(:following_id)
```

## Module Attributes for Validation

```elixir
defmodule HeadsUp.UserActivity do
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

  # In changeset
  |> validate_inclusion(:activity_type, @activity_types)

  # Public accessor
  def activity_types, do: @activity_types
end
```

**Pattern**: Use module attributes for validation lists, provide public accessor for external use.

## Token Schema Patterns

```elixir
defmodule HeadsUp.Auth.UserToken do
  @hash_algorithm :sha256
  @rand_size 32
  @reset_password_validity_in_days 1
  @confirm_validity_in_days 7
  @change_email_validity_in_days 7
  @session_validity_in_days 60

  schema "users_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string
    belongs_to :user, HeadsUp.Users
    timestamps(type: :utc_datetime, updated_at: false)
  end
end
```

**Pattern**: Use module attributes for security-related configuration (token validity, hash algorithms).
