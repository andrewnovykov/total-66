# Code Style & Conventions

## Naming Conventions

| Item                | Convention         | Example                              |
| ------------------- | ------------------ | ------------------------------------ |
| Modules             | PascalCase         | `HeadsUp.Goals`, `HeadsUpWeb.GoalLive.Show` |
| Functions           | snake_case         | `list_goals/0`, `get_user!/1`        |
| Variables           | snake_case         | `user_name`, `goal_id`               |
| Module attributes   | @snake_case        | `@activity_types`, `@xp_rewards`     |
| Contexts            | Plural noun        | `Goals`, `Accounts`, `Groups`        |
| Schemas             | Singular noun      | `Goal`, `User`, `GoalStep`           |
| LiveViews           | Resource.Action    | `GoalLive.Index`, `GoalLive.Show`    |
| Function components | snake_case         | `goal_card/1`, `commitment_chart/1`  |
| Database tables     | snake_case, plural | `goals`, `user_activities`           |
| Database columns    | snake_case         | `created_at`, `user_id`, `is_frozen` |
| Env variables       | UPPER_SNAKE        | `DATABASE_URL`, `SECRET_KEY_BASE`    |
| Routes              | kebab-case         | `/my-goals`, `/goal-posts`           |
| CSS classes         | Tailwind utilities | `bg-blue-500`, `text-gray-700`       |

### Context Function Naming Patterns

| Pattern                | Example                              | Description                    |
| ---------------------- | ------------------------------------ | ------------------------------ |
| `list_*`               | `list_goals/0`                       | Returns all records            |
| `list_*_by_*`          | `list_goals_by_user/1`               | Filtered list queries          |
| `get_*`                | `get_goal/1`                         | Returns record or nil          |
| `get_*!`               | `get_goal!/1`                        | Returns record or raises       |
| `create_*`             | `create_goal/1`                      | Creates new record             |
| `update_*`             | `update_goal/2`                      | Updates existing record        |
| `delete_*`             | `delete_goal/1`                      | Hard deletes record            |
| `soft_delete_*`        | `soft_delete_goal/1`                 | Sets deleted_at timestamp      |
| `change_*`             | `change_goal/2`                      | Returns changeset for forms    |
| `*_with_ownership`     | `update_goal_with_ownership/3`       | Validates user owns resource   |
| `*?`                   | `user_liked_goal?/2`                 | Returns boolean                |
| `toggle_*`             | `toggle_goal_step_completion/1`      | Flip operations                |

---

## Formatter Configuration

**Tool:** mix format (Elixir built-in formatter)

```elixir
# .formatter.exs
[
  import_deps: [:ecto, :ecto_sql, :phoenix],
  subdirectories: ["priv/*/migrations"],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}", "priv/*/seeds.exs"]
]
```

### Key Formatting Rules

- **Line length:** 98 characters (Elixir default)
- **Indentation:** 2 spaces
- **Trailing commas:** Automatically added by formatter
- **Parentheses:** Required for zero-arity function calls in pipes

---

## Code Quality Tools

### Credo (Static Analysis)

```elixir
# .credo.exs (key rules)
%{
  configs: [
    %{
      name: "default",
      checks: [
        {Credo.Check.Readability.MaxLineLength, max_length: 120},
        {Credo.Check.Design.TagTODO, exit_status: 0},
        {Credo.Check.Design.TagFIXME, exit_status: 0}
      ]
    }
  ]
}
```

### Dialyzer (Type Checking)

```bash
mix dialyzer
```

---

## Import Ordering

Imports should follow this order in module files:

```elixir
defmodule HeadsUp.Goals do
  # 1. use statements
  use Ecto.Schema

  # 2. import statements
  import Ecto.Query, warn: false
  import Ecto.Changeset

  # 3. alias statements (grouped by namespace)
  alias HeadsUp.Repo
  alias HeadsUp.{Goal, GoalStep, GoalLike}
  alias HeadsUp.Goals.GoalPost

  # 4. require statements
  require Logger

  # 5. Module attributes
  @activity_types ["goal_created", "goal_completed"]

  # 6. Function definitions
  def list_goals do
    # ...
  end
end
```

---

## Schema Patterns

### Standard Schema Structure

```elixir
defmodule HeadsUp.Goal do
  use Ecto.Schema
  import Ecto.Changeset

  schema "goals" do
    # Basic fields
    field :title, :string
    field :description, :string
    field :progress, :integer, default: 0

    # Ecto.Enum fields
    field :status, Ecto.Enum,
      values: [:active, :completed, :paused, :cancelled, :frozen, :failed, :deleted],
      default: :active
    field :privacy, Ecto.Enum, values: [:public, :private, :friends], default: :public

    # DateTime fields
    field :target_date, :utc_datetime
    field :deleted_at, :utc_datetime

    # Associations
    belongs_to :user, HeadsUp.Users
    belongs_to :group, HeadsUp.Group
    has_many :goal_steps, HeadsUp.GoalStep, preload_order: [asc: :order]
    has_many :goal_posts, HeadsUp.Goals.GoalPost
    has_many :likes, through: [:goal_likes, :user]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(goal, attrs) do
    goal
    |> cast(attrs, [:title, :description, :status, :privacy, :target_date, :progress])
    |> validate_required([:title, :group_id, :user_id])
    |> validate_inclusion(:progress, 0..100)
    |> custom_validations()
    |> foreign_key_constraint(:group_id)
    |> foreign_key_constraint(:user_id)
  end
end
```

### Changeset Order of Operations

1. `cast` - Extract permitted fields
2. `validate_required` - Required field validation
3. `validate_*` - Field-specific validations (length, format, inclusion)
4. Custom validations
5. `unique_constraint` / `foreign_key_constraint` - Database constraints

---

## Context Patterns

### Standard Context Structure

```elixir
defmodule HeadsUp.Goals do
  import Ecto.Query, warn: false
  alias HeadsUp.Repo
  alias HeadsUp.{Goal, GoalStep, GoalLike}

  # List functions
  def list_goals do
    from(g in Goal, where: is_nil(g.deleted_at))
    |> Repo.all()
    |> Repo.preload([:group, :user, :goal_steps])
  end

  # Get functions
  def get_goal!(id), do: Repo.get!(Goal, id)

  # Create functions
  def create_goal(attrs \\ %{}) do
    %Goal{}
    |> Goal.changeset(attrs)
    |> Repo.insert()
  end

  # Ownership-protected functions
  def update_goal_with_ownership(%Goal{} = goal, attrs, user_id) do
    cond do
      goal.user_id != user_id -> {:error, :unauthorized}
      goal.is_frozen -> {:error, :frozen}
      true -> update_goal(goal, attrs)
    end
  end
end
```

### Error Tuple Pattern

All context functions return standardized tuples:

```elixir
# Success
{:ok, resource}

# Errors
{:error, :unauthorized}
{:error, :not_found}
{:error, :frozen}
{:error, :cannot_like_own_goal}
{:error, %Ecto.Changeset{}}
```

---

## LiveView Patterns

### Standard LiveView Structure

```elixir
defmodule HeadsUpWeb.GoalLive.Show do
  use HeadsUpWeb, :live_view
  alias HeadsUp.Goals

  @impl true
  def mount(%{"id" => goal_id}, _session, socket) do
    {goal_id, _} = Integer.parse(goal_id)
    current_user = socket.assigns[:current_user]

    goal = Goals.get_goal!(goal_id)

    socket =
      socket
      |> assign(:goal, goal)
      |> assign(:page_title, goal.title)

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_like", _params, socket) do
    # Handle event
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto">
      <!-- Content -->
    </div>
    """
  end
end
```

### Key Patterns

- Use `@impl true` for LiveView callbacks
- Access `current_user` with bracket notation `socket.assigns[:current_user]` (nil-safe)
- Parse string IDs from params with `Integer.parse/1`
- Chain socket assigns with `|>`

---

## Function Component Patterns

### Standard Component Structure

```elixir
defmodule HeadsUpWeb.Components.GoalCard do
  use Phoenix.Component

  attr :goal, :map, required: true
  attr :show_category, :boolean, default: true
  attr :clickable, :boolean, default: true
  attr :current_user_id, :integer, default: nil

  def goal_card(assigns) do
    ~H"""
    <div class={"bg-white rounded-lg #{if @clickable, do: "cursor-pointer"}"}>
      <!-- Content -->
    </div>
    """
  end

  defp status_class(:active), do: "bg-green-100 text-green-800"
  defp status_class(:completed), do: "bg-blue-100 text-blue-800"
  defp status_class(_), do: "bg-gray-100 text-gray-800"
end
```

---

## Template (HEEx) Patterns

### Conditional Rendering

```heex
<%= if @current_user do %>
  <!-- Authenticated content -->
<% else %>
  <!-- Guest content -->
<% end %>

<%= case @goal.privacy do %>
  <% :public -> %> Public
  <% :friends -> %> Friends Only
  <% _ -> %> Private
<% end %>
```

### List Iteration

```heex
<%= for goal <- @goals do %>
  <.goal_card goal={goal} />
<% end %>

<div :for={goal <- @goals}>
  <!-- Alternative syntax -->
</div>
```

### Dynamic Classes

```heex
class={"px-2 py-1 rounded-full #{status_class(@goal.status)}"}

class={[
  "py-2 px-1 font-medium",
  if(@active_tab == "goals", do: "border-blue-500", else: "border-transparent")
]}
```

---

## Migration Patterns

### Creating Tables

```elixir
def change do
  create table(:goals) do
    add :title, :string, null: false
    add :status, :string, default: "active"
    add :user_id, references(:users, on_delete: :delete_all), null: false

    timestamps(type: :utc_datetime)
  end

  create index(:goals, [:user_id])
  create index(:goals, [:status])
end
```

### Reference Delete Behaviors

| Behavior | Use Case |
| -------- | -------- |
| `:delete_all` | Owned relationships (user's goals) |
| `:nilify_all` | Optional relationships (activity's goal) |
| `:restrict` | Required relationships (prevent orphans) |
| `:nothing` | Manual handling required |

---

## Test Patterns

### DataCase Test Structure

```elixir
defmodule HeadsUp.GoalOwnershipTest do
  use HeadsUp.DataCase, async: true
  alias HeadsUp.Goals
  import HeadsUp.AuthFixtures

  describe "goal ownership validation" do
    setup do
      owner = user_fixture()
      other_user = user_fixture()
      {:ok, goal} = Goals.create_goal(%{title: "Test", user_id: owner.id})

      %{goal: goal, owner: owner, other_user: other_user}
    end

    test "owner can update goal", %{goal: goal, owner: owner} do
      assert {:ok, updated} = Goals.update_goal_with_ownership(goal, %{title: "New"}, owner.id)
      assert updated.title == "New"
    end

    test "non-owner cannot update goal", %{goal: goal, other_user: other_user} do
      assert {:error, :unauthorized} = Goals.update_goal_with_ownership(goal, %{title: "New"}, other_user.id)
    end
  end
end
```

---

## Error Handling Patterns

### Context Error Handling

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

### LiveView Error Handling

```elixir
def handle_event("save", %{"goal" => params}, socket) do
  case Goals.update_goal_with_ownership(socket.assigns.goal, params, socket.assigns.current_user_id) do
    {:ok, goal} ->
      {:noreply,
       socket
       |> put_flash(:info, "Goal updated")
       |> push_navigate(to: ~p"/goals/#{goal.id}")}

    {:error, :unauthorized} ->
      {:noreply, put_flash(socket, :error, "Not authorized")}

    {:error, %Ecto.Changeset{} = changeset} ->
      {:noreply, assign(socket, :form, to_form(changeset))}
  end
end
```

### Forbidden Patterns

- [ ] No empty `rescue` blocks
- [ ] No `Repo` calls directly in LiveViews (use contexts)
- [ ] No hardcoded secrets or URLs
- [ ] No `IO.inspect` in production code (use Logger)
- [ ] No self-referencing actions (like own goal, follow self)

---

## Git Workflow

### Branch Naming

```
[type]/[short-description]

Types: feat, fix, chore, refactor, docs, test
Examples: feat/user-registration, fix/login-redirect, chore/update-deps
```

### Commit Messages (Conventional Commits)

```
[type]([scope]): [description]

Types: feat, fix, chore, refactor, docs, test, perf, ci
Scope: optional, e.g., auth, goals, ui

Examples:
  feat(goals): add goal freeze functionality
  fix(auth): handle duplicate email registration
  chore: update Phoenix to 1.7.21
```

### Branch Strategy

- [x] GitHub Flow (`main` + feature branches)
- Feature branches off `main`
- Pull requests for all changes
- Squash merge to `main`

---

## Pull Request Template

```markdown
## What

[Brief description of the change]

## Why

[Why is this change needed?]

## How

[Key implementation details]

## Testing

- [ ] Unit tests added/updated
- [ ] LiveView tests if UI changed
- [ ] Tested manually in browser
- [ ] `mix format` passes
- [ ] `mix test` passes

## Screenshots (if UI change)

[Before/after screenshots]
```
