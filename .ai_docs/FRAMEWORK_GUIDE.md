# HeadsUp Framework Guide

## Overview

This document serves as a meta-instruction for AI coding assistants to generate features aligned with the HeadsUp project's Elixir/Phoenix/LiveView architecture and coding style. All patterns documented here are based on actual, observed conventions from the codebase—not invented best practices.

**Purpose**: Enable consistent, convention-following code generation for the HeadsUp social goal tracking platform.

---

## Tech Stack Summary

| Component | Version | Purpose |
|-----------|---------|---------|
| Elixir | ~> 1.14 | Core language |
| Phoenix | ~> 1.7.21 | Web framework |
| Phoenix LiveView | ~> 1.0.10 | Real-time UI |
| PostgreSQL | Latest | Database |
| Ecto | ~> 3.12.5 | Database ORM |
| Tailwind CSS | 3.4.3 | Styling |
| Bandit | ~> 1.5 | HTTP server |
| bcrypt_elixir | ~> 3.0 | Password hashing |

---

## File Category Reference

### Contexts (`lib/heads_up/*.ex`)

**Purpose**: Bounded domain logic modules providing the API for database operations.

**Examples**:
- `lib/heads_up/goals.ex` - Goal management operations
- `lib/heads_up/accounts.ex` - User relationships (follows, friendships)

**Key Conventions**:
- Function naming: `list_*`, `get_*`, `get_*!`, `create_*`, `update_*`, `delete_*`
- Ownership validation: `*_with_ownership(resource, attrs, user_id)` suffix
- Error returns: `{:ok, resource}` or `{:error, :reason}`
- Query filtering: Always exclude soft-deleted records (`is_nil(deleted_at)`)

```elixir
def update_goal_with_ownership(%Goal{} = goal, attrs, user_id) do
  cond do
    goal.user_id != user_id -> {:error, :unauthorized}
    goal.status == :failed -> {:error, :failed}
    goal.is_frozen -> {:error, :frozen}
    true -> update_goal(goal, attrs)
  end
end
```

### Services (`lib/heads_up/*_service.ex`)

**Purpose**: Complex business logic and cross-cutting concerns.

**Examples**:
- `lib/heads_up/activity_service.ex` - XP tracking, level progression
- `lib/heads_up/feed_service.ex` - Social feed generation

**Key Conventions**:
- Module attributes for configuration (`@xp_rewards`, `@level_thresholds`)
- Transaction wrapping for multi-step operations
- Stateless modules (no GenServer state)

### Schemas (`lib/heads_up/*.ex`, `lib/heads_up/*/*.ex`)

**Purpose**: Ecto schemas mapping to database tables.

**Examples**:
- `lib/heads_up/goal.ex` - Goal entity
- `lib/heads_up/users.ex` - User entity (note: plural naming from auth generator)

**Key Conventions**:
- Use `Ecto.Enum` for status/type fields
- Always include `timestamps(type: :utc_datetime)`
- Soft delete with `deleted_at` field
- Multiple changeset functions for different use cases

```elixir
schema "goals" do
  field :status, Ecto.Enum,
    values: [:active, :completed, :paused, :cancelled, :frozen, :failed, :deleted],
    default: :active
  field :deleted_at, :utc_datetime
  belongs_to :user, HeadsUp.Users
  has_many :goal_steps, HeadsUp.GoalStep, preload_order: [asc: :order]
  timestamps(type: :utc_datetime)
end
```

### LiveViews (`lib/heads_up_web/live/*`)

**Purpose**: Real-time UI modules with server-side state.

**Examples**:
- `lib/heads_up_web/live/goal_live/show.ex` - Goal detail view
- `lib/heads_up_web/live/feed_live/index.ex` - Activity feed

**Key Conventions**:
- Use `HeadsUpWeb, :live_view` macro
- Access `current_user` via `socket.assigns[:current_user]` (nil-safe) or `socket.assigns.current_user` (guaranteed authenticated)
- Subscribe to PubSub only when `connected?(socket)`
- Dispatch to private `save_*` functions based on action

```elixir
def mount(%{"id" => goal_id}, _session, socket) do
  {goal_id, _} = Integer.parse(goal_id)
  current_user = socket.assigns[:current_user]
  goal = Goals.get_goal!(goal_id)

  if goal.privacy == :public or (current_user && goal.user_id == current_user.id) do
    {:ok, assign(socket, :goal, goal)}
  else
    {:ok, socket |> put_flash(:error, "Access denied") |> push_navigate(to: ~p"/goals")}
  end
end
```

### LiveComponents (`lib/heads_up_web/live/*_component.ex`)

**Purpose**: Reusable stateful components.

**Examples**:
- `lib/heads_up_web/live/goal_live/form_component.ex`

**Key Conventions**:
- Implement `update/2` callback
- Require unique `id` assign
- Handle form validate/save events

### Function Components (`lib/heads_up_web/components/*.ex`)

**Purpose**: Stateless UI building blocks.

**Examples**:
- `lib/heads_up_web/components/core_components.ex` - Standard Phoenix components
- `lib/heads_up_web/components/goal_card.ex` - Goal display card
- `lib/heads_up_web/components/commitment_chart.ex` - Activity heatmap

**Key Conventions**:
- Use `attr` macro for type declarations
- Use `slot` macro for content injection
- Pattern match for CSS class helpers

```elixir
attr :goal, :map, required: true
attr :current_user_id, :integer, default: nil

def goal_card(assigns) do
  ~H"""
  <div class="bg-white rounded-lg shadow-md">
    <!-- content -->
  </div>
  """
end
```

### Controllers (`lib/heads_up_web/controllers/*.ex`)

**Purpose**: Traditional HTTP request handlers and API endpoints.

**Examples**:
- `lib/heads_up_web/controllers/api/goal_controller.ex`
- `lib/heads_up_web/controllers/user_session_controller.ex`

**Key Conventions**:
- Use `action_fallback HeadsUpWeb.FallbackController`
- Separate JSON view modules (`*_json.ex`)
- Return consistent JSON structure

### Plugs (`lib/heads_up_web/*_auth.ex`)

**Purpose**: Authentication and authorization middleware.

**Examples**:
- `lib/heads_up_web/user_auth.ex` - User authentication
- `lib/heads_up_web/admin_auth.ex` - Admin authorization

**Key Conventions**:
- Implement both Plug functions and `on_mount` callbacks for LiveView
- Return JSON error for API routes (`require_authenticated_user_api`)

---

## Feature Scaffold Guide

When implementing a new feature, follow this structure:

### Example: Adding "Challenges" Feature

```
lib/
├── heads_up/
│   ├── challenge.ex                    # Schema
│   └── challenges.ex                   # Context
└── heads_up_web/
    ├── live/
    │   └── challenge_live/
    │       ├── index.ex               # List view
    │       ├── show.ex                # Detail view
    │       └── form_component.ex      # Form component
    └── controllers/
        └── api/
            ├── challenge_controller.ex # API controller
            └── challenge_json.ex       # JSON view

priv/repo/migrations/
└── YYYYMMDDHHMMSS_create_challenges.exs

test/
├── heads_up/
│   └── challenges_test.exs            # Context tests
└── heads_up_web/
    ├── live/
    │   └── challenge_live_test.exs    # LiveView tests
    └── controllers/
        └── api/
            └── challenge_controller_test.exs
```

### File Creation Order

1. **Migration** - Create database table
2. **Schema** - Define Ecto schema with associations
3. **Context** - Implement CRUD and business logic
4. **LiveViews** - Build UI components
5. **API Controller** (optional) - Add JSON endpoints
6. **Tests** - Cover context and LiveView functionality

### Naming Conventions

| Resource | Module Name | Table Name | File Path |
|----------|-------------|------------|-----------|
| Challenge | `HeadsUp.Challenge` | `challenges` | `lib/heads_up/challenge.ex` |
| Challenge Step | `HeadsUp.ChallengeStep` | `challenge_steps` | `lib/heads_up/challenge_step.ex` |
| Context | `HeadsUp.Challenges` | - | `lib/heads_up/challenges.ex` |
| LiveView | `HeadsUpWeb.ChallengeLive.Index` | - | `lib/heads_up_web/live/challenge_live/index.ex` |

---

## Integration Rules

### Data Access

1. **Never call Repo directly from LiveViews or controllers** - Always go through context modules
2. **All database operations through contexts** - `HeadsUp.Goals.create_goal(attrs)` not `Repo.insert()`
3. **Preload associations explicitly** - Never rely on lazy loading

### Ownership & Authorization

1. **Use `*_with_ownership` pattern** for user-scoped mutations
2. **Return descriptive error atoms** - `:unauthorized`, `:frozen`, `:not_found`
3. **Prevent self-interaction** - Users cannot like/subscribe to their own content

```elixir
def like_goal(goal_id, user_id) do
  goal = get_goal!(goal_id)
  if goal.user_id == user_id do
    {:error, :cannot_like_own_goal}
  else
    # proceed with like
  end
end
```

### Activity Tracking

1. **All significant actions must call ActivityService.track_activity**
2. **Include relevant metadata** - `goal_id`, `post_id`, `description`
3. **XP can be positive or negative** - Failures/deletions have negative XP

```elixir
case result do
  {:ok, goal} ->
    ActivityService.track_activity(user_id, "goal_created",
      goal_id: goal.id,
      description: "Created goal: #{goal.title}"
    )
    {:ok, goal}
  error -> error
end
```

### Forms & Changesets

1. **All forms must use changesets** with proper validations
2. **Use `to_form/1`** to create form assigns
3. **Handle changeset errors** in UI

### Real-Time Updates

1. **Use Phoenix PubSub** for real-time features
2. **Subscribe in mount** only when `connected?(socket)`
3. **Topic naming** - Use descriptive strings: `"user_activities"`, `"goals:#{id}"`

### Routing

1. **LiveViews grouped in `live_session`** with shared `on_mount` hooks
2. **Admin routes require** both `ensure_authenticated` and `ensure_admin`
3. **API routes** under `/api` scope with JSON pipeline

---

## Error Handling Patterns

### Standard Error Tuples

```elixir
{:ok, resource}              # Success
{:error, :unauthorized}      # Permission denied
{:error, :not_found}         # Resource not found
{:error, :frozen}            # Resource is frozen
{:error, :failed}            # Resource in failed state
{:error, changeset}          # Validation errors
{:error, :cannot_like_own_goal}    # Business logic constraint
{:error, :user_is_private}   # Privacy restriction
```

### LiveView Error Handling

```elixir
case Goals.update_goal_with_ownership(goal, attrs, user_id) do
  {:ok, goal} ->
    {:noreply, socket |> put_flash(:info, "Updated") |> push_navigate(to: ~p"/goals/#{goal}")}
  {:error, :unauthorized} ->
    {:noreply, put_flash(socket, :error, "Not authorized")}
  {:error, %Ecto.Changeset{} = changeset} ->
    {:noreply, assign(socket, :form, to_form(changeset))}
end
```

---

## Example Prompt Usage

### User Request
> "Create a feature for users to manage challenge templates with CRUD operations"

### AI Response Structure

1. **Migration** (`priv/repo/migrations/TIMESTAMP_create_challenge_templates.exs`):
```elixir
def change do
  create table(:challenge_templates) do
    add :title, :string, null: false
    add :description, :text
    add :difficulty, :string, default: "medium"
    add :user_id, references(:users, on_delete: :delete_all), null: false
    timestamps(type: :utc_datetime)
  end
  create index(:challenge_templates, [:user_id])
end
```

2. **Schema** (`lib/heads_up/challenge_template.ex`):
```elixir
defmodule HeadsUp.ChallengeTemplate do
  use Ecto.Schema
  import Ecto.Changeset

  schema "challenge_templates" do
    field :title, :string
    field :description, :string
    field :difficulty, Ecto.Enum, values: [:easy, :medium, :hard], default: :medium
    belongs_to :user, HeadsUp.Users
    timestamps(type: :utc_datetime)
  end

  def changeset(template, attrs) do
    template
    |> cast(attrs, [:title, :description, :difficulty, :user_id])
    |> validate_required([:title, :user_id])
    |> foreign_key_constraint(:user_id)
  end
end
```

3. **Context** (`lib/heads_up/challenge_templates.ex`):
```elixir
defmodule HeadsUp.ChallengeTemplates do
  import Ecto.Query, warn: false
  alias HeadsUp.{Repo, ChallengeTemplate, ActivityService}

  def list_templates_by_user(user_id) do
    from(t in ChallengeTemplate, where: t.user_id == ^user_id)
    |> Repo.all()
  end

  def create_template(attrs) do
    result = %ChallengeTemplate{}
      |> ChallengeTemplate.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, template} ->
        ActivityService.track_activity(template.user_id, "template_created",
          description: "Created template: #{template.title}")
        {:ok, template}
      error -> error
    end
  end

  def update_template_with_ownership(%ChallengeTemplate{} = template, attrs, user_id) do
    if template.user_id == user_id do
      template |> ChallengeTemplate.changeset(attrs) |> Repo.update()
    else
      {:error, :unauthorized}
    end
  end
end
```

4. **LiveView** (`lib/heads_up_web/live/challenge_template_live/index.ex`):
```elixir
defmodule HeadsUpWeb.ChallengeTemplateLive.Index do
  use HeadsUpWeb, :live_view
  alias HeadsUp.ChallengeTemplates

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    templates = ChallengeTemplates.list_templates_by_user(current_user.id)
    {:ok, assign(socket, :templates, templates)}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto p-4">
      <h1 class="text-2xl font-bold">My Challenge Templates</h1>
      <div :for={template <- @templates} class="bg-white rounded-lg shadow p-4 mt-4">
        <h2 class="font-semibold"><%= template.title %></h2>
      </div>
    </div>
    """
  end
end
```

---

## Quick Reference

### Module Boilerplates

**Schema**:
```elixir
defmodule HeadsUp.ResourceName do
  use Ecto.Schema
  import Ecto.Changeset

  schema "table_name" do
    belongs_to :user, HeadsUp.Users
    timestamps(type: :utc_datetime)
  end

  def changeset(resource, attrs) do
    resource
    |> cast(attrs, [:field1, :field2, :user_id])
    |> validate_required([:field1, :user_id])
    |> foreign_key_constraint(:user_id)
  end
end
```

**Context**:
```elixir
defmodule HeadsUp.Resources do
  import Ecto.Query, warn: false
  alias HeadsUp.{Repo, ResourceName}

  def list_resources, do: Repo.all(ResourceName)
  def get_resource!(id), do: Repo.get!(ResourceName, id)
  def create_resource(attrs), do: %ResourceName{} |> ResourceName.changeset(attrs) |> Repo.insert()
  def change_resource(%ResourceName{} = resource, attrs \\ %{}), do: ResourceName.changeset(resource, attrs)
end
```

**LiveView**:
```elixir
defmodule HeadsUpWeb.ResourceLive.Index do
  use HeadsUpWeb, :live_view
  alias HeadsUp.Resources

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :resources, Resources.list_resources())}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto p-4">
      <!-- content -->
    </div>
    """
  end
end
```

---

## Files Generated By This Guide

| File | Purpose |
|------|---------|
| `.ai_docs/1-techstack.md` | Technology stack analysis |
| `.ai_docs/2-file-categorization.json` | File category mapping |
| `.ai_docs/3-architectural-domains.json` | Domain patterns & constraints |
| `.ai_docs/4-domains/*.md` | Deep-dive per domain |
| `.ai_docs/5-style-guides/*.md` | Style guide per category |
| `.ai_docs/FRAMEWORK_GUIDE.md` | This synthesized guide |

---

*Generated for HeadsUp - Social Goal Tracking Platform*
*Based on actual codebase patterns as of 2026-01-28*
