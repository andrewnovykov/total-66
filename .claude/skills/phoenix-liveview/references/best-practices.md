# Phoenix/Ecto Best Practices

## N+1 Query Prevention

### The Problem

N+1 queries occur when you iterate through a collection and make a database query for each item. This causes severe performance degradation as data grows.

**Bad Pattern (N+1 queries):**
```elixir
defp add_goal_counts(groups) do
  # Makes 1 query per group = N+1 total queries!
  Enum.map(groups, fn group ->
    goal_count = Groups.count_goals_in_group(group.id)
    Map.put(group, :goal_count, goal_count)
  end)
end

def count_goals_in_group(group_id) do
  from(g in Goal, where: g.group_id == ^group_id, select: count(g.id))
  |> Repo.one()
end
```

With 100 groups, this executes **101 queries** (1 for groups + 100 for counts).

### The Solution

Fetch all counts in a single batched query using `GROUP BY`, then map in memory.

**Good Pattern (2 queries total):**
```elixir
defp add_goal_counts(groups) do
  group_ids = Enum.map(groups, & &1.id)
  counts_map = Groups.goal_counts_by_group_ids(group_ids)

  Enum.map(groups, fn group ->
    Map.put(group, :goal_count, Map.get(counts_map, group.id, 0))
  end)
end

def goal_counts_by_group_ids(group_ids) when is_list(group_ids) do
  from(g in Goal,
    where: g.group_id in ^group_ids,
    group_by: g.group_id,
    select: {g.group_id, count(g.id)}
  )
  |> Repo.all()
  |> Map.new()
end
```

With 100 groups, this executes only **2 queries** regardless of count.

### Multiple Aggregates

When you need multiple counts (e.g., total and active), use separate queries but still batch:

```elixir
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

  # Build map with both counts for each group
  Enum.reduce(group_ids, %{}, fn group_id, acc ->
    counts = %{
      total_goal_amount: Map.get(total_counts, group_id, 0),
      active_goal_amount: Map.get(active_counts, group_id, 0)
    }
    Map.put(acc, group_id, counts)
  end)
end
```

### When to Watch for N+1

1. **LiveView `mount/3`** - Loading lists with associated data
2. **Index pages** - Displaying counts, statuses, or related data
3. **API endpoints** - JSON responses with nested data
4. **Any `Enum.map` that calls the database**

### Detection

Signs of N+1 queries:
- Slow page loads that worsen with more data
- Database query count equals record count + 1
- `Repo.one()` or `Repo.get()` inside `Enum.map/2`

### Related Patterns

**Preloading associations:**
```elixir
# Bad: N+1 when accessing post.user
posts = Repo.all(Post)
Enum.each(posts, fn post -> IO.puts(post.user.name) end)

# Good: Single query with preload
posts = Repo.all(Post) |> Repo.preload(:user)
```

**Inline preload in query:**
```elixir
from(p in Post,
  preload: [:user, :comments],
  where: p.status == :published
)
|> Repo.all()
```

---

## Use `Repo.exists?` for Boolean Checks

### The Problem

Using `COUNT` to check if records exist is inefficient because it scans all matching rows.

**Bad Pattern:**
```elixir
def has_goals?(group_id) do
  count_goals_in_group(group_id) > 0  # Counts ALL matching records
end

def count_goals_in_group(group_id) do
  from(g in Goal, where: g.group_id == ^group_id, select: count(g.id))
  |> Repo.one()
end
```

If a group has 10,000 goals, this counts all 10,000 before returning `true`.

### The Solution

Use `Repo.exists?/1` which translates to SQL `EXISTS` - it stops at the first match.

**Good Pattern:**
```elixir
def has_goals?(group_id) do
  from(g in Goal, where: g.group_id == ^group_id)
  |> Repo.exists?()
end
```

This returns `true` as soon as it finds the first goal, regardless of how many exist.

### When to Use

- **`Repo.exists?/1`** - When you only need a boolean (does it exist?)
- **`Repo.aggregate/3` with `:count`** - When you need the actual count
- **Batched `GROUP BY` queries** - When you need counts for multiple items

---

## Form Handling with `to_form/2`

### The Problem

Using raw `Ecto.Changeset` directly in templates causes errors because `Ecto.Changeset` doesn't implement the `Access` behavior.

**Bad Pattern:**
```elixir
# In mount
socket = assign(socket, :changeset, Groups.change_group(%Group{}))

# In template - FAILS with UndefinedFunctionError
<.input field={@changeset[:name]} />
```

### The Solution

Always convert changesets to Phoenix forms using `to_form/2`:

```elixir
# In mount
changeset = Groups.change_group(%Group{})
socket = assign(socket, :form, to_form(changeset, as: "group"))

# In template - Works correctly
<.input field={@form[:name]} />
```

### Modal Forms Pattern

When using modals with forms, reset the form state when opening:

```elixir
def handle_event("show_create_modal", _params, socket) do
  changeset = Groups.change_group(%Group{})
  {:noreply, assign(socket, show_modal: true, form: to_form(changeset, as: "group"))}
end

def handle_event("create", %{"group" => params}, socket) do
  case Groups.create_group(params) do
    {:ok, _group} ->
      {:noreply,
       socket
       |> put_flash(:info, "Created!")
       |> assign(:show_modal, false)}

    {:error, changeset} ->
      # Re-wrap changeset as form to show errors
      {:noreply, assign(socket, :form, to_form(changeset, as: "group"))}
  end
end
```

---

## Centralized Role Checking

### The Problem

Duplicating role check logic across multiple files leads to inconsistencies and maintenance burden.

**Bad Pattern:**
```elixir
# In LiveView 1
if user && user.role in ["coach", "admin"], do: ...

# In LiveView 2
if user && user.role == "admin", do: ...

# In template
<%= if @current_user && @current_user.role == "admin" do %>
```

### The Solution

Create a centralized helper module:

```elixir
defmodule MyAppWeb.Helpers.RoleHelper do
  @admin_role "admin"
  @coach_role "coach"

  def is_admin?(nil), do: false
  def is_admin?(%{role: role}), do: role == @admin_role

  def is_coach?(nil), do: false
  def is_coach?(%{role: role}), do: role == @coach_role

  def is_coach_or_admin?(nil), do: false
  def is_coach_or_admin?(%{role: role}), do: role in [@coach_role, @admin_role]

  def has_role_at_least?(nil, _required_role), do: false
  def has_role_at_least?(%{role: role}, required_role) do
    role_level(role) >= role_level(required_role)
  end

  defp role_level("user"), do: 1
  defp role_level("coach"), do: 2
  defp role_level("admin"), do: 3
  defp role_level(_), do: 0
end
```

**Usage:**
```elixir
# In LiveView
import MyAppWeb.Helpers.RoleHelper

def mount(_params, _session, socket) do
  if not is_admin?(socket.assigns.current_user) do
    {:ok, redirect(socket, to: "/")}
  else
    {:ok, socket}
  end
end

# In template
<%= if is_admin?(@current_user) do %>
  <.link navigate={~p"/admin"}>Admin Panel</.link>
<% end %>
```

---

## Safe Deletion Pattern

### The Problem

Deleting records that have foreign key references can fail or cause data integrity issues.

### The Solution

Check for dependencies before deletion:

```elixir
def safe_delete_group(%Group{} = group) do
  goal_count = count_goals_in_group(group.id)

  if goal_count > 0 do
    {:error, :has_goals, goal_count}
  else
    delete_group(group)
  end
end
```

**In LiveView:**
```elixir
def handle_event("delete", %{"id" => id}, socket) do
  group = Groups.get_group!(id)

  case Groups.safe_delete_group(group) do
    {:ok, _} ->
      {:noreply,
       socket
       |> put_flash(:info, "Deleted!")
       |> assign(:groups, Groups.list_groups())}

    {:error, :has_goals, count} ->
      {:noreply,
       put_flash(socket, :error,
         "Cannot delete: #{count} goal(s) are using this category.")}
  end
end
```
