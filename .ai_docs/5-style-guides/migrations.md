# Migrations Style Guide

This style guide documents the patterns and conventions used in HeadsUp Ecto migrations.

## File Organization

```
priv/repo/migrations/
  20250523224942_create_users.exs
  20250524180235_add_about_to_users.exs
  20250705080710_create_goals.exs
  20250705153638_create_goal_likes.exs
  ...
```

**Naming**: `YYYYMMDDHHMMSS_description.exs`

## Module Structure

```elixir
defmodule HeadsUp.Repo.Migrations.CreateGoals do
  use Ecto.Migration

  def change do
    # Migration operations
  end
end
```

**Pattern**: Module name matches filename (CamelCase).

## Creating Tables

### Basic Table

```elixir
def change do
  create table(:goals) do
    add :title, :string, null: false
    add :description, :text
    add :status, :string, default: "active"
    add :target_date, :utc_datetime
    add :progress, :integer, default: 0
    add :group_id, references(:groups, on_delete: :delete_all)
    add :user_id, references(:users, on_delete: :delete_all)

    timestamps(type: :utc_datetime)
  end

  create index(:goals, [:group_id])
  create index(:goals, [:user_id])
  create index(:goals, [:status])
end
```

**Pattern**:
- Use `null: false` for required fields
- Use `default:` for fields with default values
- Use `timestamps(type: :utc_datetime)` for UTC timestamps
- Create indexes for foreign keys and frequently queried fields

### Join Table

```elixir
def change do
  create table(:goal_likes) do
    add :goal_id, references(:goals, on_delete: :delete_all), null: false
    add :user_id, references(:users, on_delete: :delete_all), null: false

    timestamps(type: :utc_datetime)
  end

  create index(:goal_likes, [:goal_id])
  create index(:goal_likes, [:user_id])
  create unique_index(:goal_likes, [:goal_id, :user_id])
end
```

**Pattern**: Unique index prevents duplicate entries.

### Self-Referencing Table

```elixir
def change do
  create table(:friendships) do
    add :user_id, references(:users, on_delete: :delete_all), null: false
    add :friend_id, references(:users, on_delete: :delete_all), null: false
    add :status, :string, default: "pending", null: false

    timestamps()
  end

  create index(:friendships, [:user_id])
  create index(:friendships, [:friend_id])
  create index(:friendships, [:status])
  create unique_index(:friendships, [:user_id, :friend_id])
end
```

**Pattern**: Both foreign keys reference same table.

### Activity Tracking Table

```elixir
def change do
  create table(:user_activities) do
    add :activity_type, :string, null: false
    add :xp_change, :integer, null: false, default: 0
    add :description, :text
    add :metadata, :map, default: %{}

    add :user_id, references(:users, on_delete: :delete_all), null: false
    add :goal_id, references(:goals, on_delete: :nilify_all)
    add :post_id, references(:goal_posts, on_delete: :nilify_all)
    add :like_id, :bigint
    add :follow_id, :bigint

    timestamps(type: :utc_datetime, updated_at: false)
  end

  create index(:user_activities, [:user_id])
  create index(:user_activities, [:activity_type])
  create index(:user_activities, [:inserted_at])
  create index(:user_activities, [:user_id, :inserted_at])
end
```

**Pattern**:
- Use `:map` for JSON/metadata fields
- Use `on_delete: :nilify_all` for optional references
- Use `timestamps(updated_at: false)` for immutable records
- Compound index for common query patterns

## Altering Tables

### Adding Fields

```elixir
def change do
  alter table(:users) do
    add :about, :text
  end
end
```

### Adding Multiple Fields

```elixir
def change do
  alter table(:goals) do
    add :failure_reason, :text
    add :failed_at, :utc_datetime
    add :deleted_at, :utc_datetime
    add :is_frozen, :boolean, default: false
  end

  create index(:goals, [:deleted_at])
  create index(:goals, [:is_frozen])
end
```

**Pattern**: Add indexes after altering table.

### Adding Foreign Key

```elixir
def change do
  alter table(:goal_posts) do
    add :goal_step_id, references(:goal_steps, on_delete: :nilify_all)
  end

  create index(:goal_posts, [:goal_step_id])
end
```

### Adding Privacy Field

```elixir
def change do
  alter table(:goals) do
    add :privacy, :string, default: "public"
  end

  create index(:goals, [:privacy])
end
```

### Adding Parent Reference (Hierarchical)

```elixir
def change do
  alter table(:groups) do
    add :parent_id, references(:groups, on_delete: :nilify_all)
  end

  create index(:groups, [:parent_id])
end
```

**Pattern**: Self-reference with `on_delete: :nilify_all` for hierarchy.

## Column Types

| Elixir Type | PostgreSQL Type | Use Case |
|-------------|-----------------|----------|
| `:string` | `varchar(255)` | Short text, names |
| `:text` | `text` | Long text, descriptions |
| `:integer` | `integer` | Counts, progress |
| `:bigint` | `bigint` | Large IDs |
| `:boolean` | `boolean` | Flags |
| `:utc_datetime` | `timestamp` | Timestamps |
| `:map` | `jsonb` | Metadata, JSON |

## Reference Options

### On Delete Behaviors

```elixir
# Delete related records when parent deleted
references(:users, on_delete: :delete_all)

# Set to NULL when parent deleted
references(:goals, on_delete: :nilify_all)

# Prevent deletion if related records exist
references(:categories, on_delete: :restrict)

# Do nothing (database default)
references(:tags, on_delete: :nothing)
```

**Pattern**:
- `:delete_all` for owned relationships (user's goals)
- `:nilify_all` for optional relationships (activity's goal)
- `:restrict` for required relationships (prevent orphans)

## Index Patterns

### Single Column Index

```elixir
create index(:goals, [:user_id])
```

### Unique Index

```elixir
create unique_index(:users, [:email])
create unique_index(:users, [:user_name])
```

### Compound Index

```elixir
create unique_index(:goal_likes, [:goal_id, :user_id])
create index(:user_activities, [:user_id, :inserted_at])
```

**Pattern**: Column order matters - put most selective column first.

### Partial Index

```elixir
create index(:goals, [:deleted_at], where: "deleted_at IS NOT NULL")
```

**Pattern**: Index only rows matching condition.

## Auth Tables Migration

```elixir
def change do
  execute "CREATE EXTENSION IF NOT EXISTS citext", ""

  create table(:users) do
    add :email, :citext, null: false
    add :hashed_password, :string, null: false
    add :confirmed_at, :utc_datetime
    timestamps(type: :utc_datetime)
  end

  create unique_index(:users, [:email])

  create table(:users_tokens) do
    add :user_id, references(:users, on_delete: :delete_all), null: false
    add :token, :binary, null: false
    add :context, :string, null: false
    add :sent_to, :string
    timestamps(type: :utc_datetime, updated_at: false)
  end

  create index(:users_tokens, [:user_id])
  create unique_index(:users_tokens, [:context, :token])
end
```

**Pattern**:
- Use `citext` extension for case-insensitive email
- Use `execute` for raw SQL extensions
- Token table uses binary type for secure tokens

## Migration Order

1. Create base tables (users, groups)
2. Create dependent tables (goals depends on users, groups)
3. Create join tables (goal_likes depends on goals, users)
4. Add columns to existing tables
5. Add indexes after table structure complete

## Reversible vs Change

### Using Change (Reversible)

```elixir
def change do
  create table(:goals) do
    # ...
  end
end
```

**Pattern**: Ecto auto-generates `down` migration.

### Using Up/Down (Custom)

```elixir
def up do
  execute "CREATE EXTENSION IF NOT EXISTS citext"
end

def down do
  execute "DROP EXTENSION IF EXISTS citext"
end
```

**Pattern**: Use when `change` cannot auto-reverse.

## Timestamp Conventions

### Standard Timestamps

```elixir
timestamps(type: :utc_datetime)
```

**Pattern**: Always use UTC timestamps.

### Immutable Records

```elixir
timestamps(type: :utc_datetime, updated_at: false)
```

**Pattern**: Activities and logs don't need `updated_at`.

### Soft Delete Timestamp

```elixir
add :deleted_at, :utc_datetime
```

**Pattern**: NULL means not deleted.

### Event Timestamps

```elixir
add :failed_at, :utc_datetime
add :completed_at, :utc_datetime
add :frozen_at, :utc_datetime
```

**Pattern**: Track when specific events occurred.

## Naming Conventions

| Migration Type | Naming Pattern | Example |
|----------------|----------------|---------|
| Create table | `create_{table}` | `create_goals` |
| Add column | `add_{column}_to_{table}` | `add_about_to_users` |
| Add columns | `add_{feature}_fields` | `add_goal_tracking_fields` |
| Create join | `create_{table1}_{table2}` | `create_goal_likes` |
| Add index | `add_index_to_{table}` | `add_index_to_goals` |
