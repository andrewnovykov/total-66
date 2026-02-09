# LiveComponent Style Guide

This style guide documents the patterns and conventions used in HeadsUp LiveComponent modules.

## Module Structure

```elixir
defmodule HeadsUpWeb.GoalLive.FormComponent do
  use HeadsUpWeb, :live_component
  alias HeadsUp.Goals
  import HeadsUpWeb.Helpers.SubscriptionHelper
```

**Pattern**: Use `HeadsUpWeb, :live_component` macro, import helpers as needed.

## Naming Convention

LiveComponents are placed in the same directory as related LiveViews:

```
lib/heads_up_web/live/
  goal_live/
    index.ex          # LiveView
    show.ex           # LiveView
    edit.ex           # LiveView
    new.ex            # LiveView
    form_component.ex # LiveComponent
```

**Pattern**: Name components with `_component.ex` suffix.

## Update Callback

### Standard Update Pattern

```elixir
def update(%{goal: goal} = assigns, socket) do
  changeset = Goals.change_goal(goal)

  {:ok,
   socket
   |> assign(assigns)
   |> assign(:changeset, changeset)
   |> assign(:form, to_form(changeset))}
end
```

**Pattern**:
1. Pattern match required assigns
2. Initialize changeset from resource
3. Spread all assigns with `assign(assigns)`
4. Add computed assigns (changeset, form)

### Key Assigns Expected

When using `FormComponent`, parent must provide:

```elixir
<.live_component
  module={HeadsUpWeb.GoalLive.FormComponent}
  id="edit-goal"
  action={:edit}              # or :new
  goal={@goal}                # Resource to edit/create
  current_user_id={@current_user_id}
  current_user={@current_user}  # For subscription checks
  goal_groups={@goal_groups}    # Select options
  patch={~p"/goals"}            # Redirect target
/>
```

## Handle Event Callbacks

### Validation Event

```elixir
def handle_event("validate", %{"goal" => goal_params}, socket) do
  changeset =
    socket.assigns.goal
    |> Goals.change_goal(goal_params)
    |> Map.put(:action, :validate)

  {:noreply, socket |> assign(:changeset, changeset) |> assign(:form, to_form(changeset))}
end
```

**Pattern**: Set `:action` to `:validate` to trigger error display.

### Save Event with Action Dispatch

```elixir
def handle_event("save", %{"goal" => goal_params}, socket) do
  save_goal(socket, socket.assigns.action, goal_params)
end

defp save_goal(socket, :edit, goal_params) do
  case Goals.update_goal_with_ownership(socket.assigns.goal, goal_params, socket.assigns.current_user_id) do
    {:ok, _goal} ->
      {:noreply,
       socket
       |> put_flash(:info, "Goal updated successfully")
       |> push_navigate(to: socket.assigns.patch)}

    {:error, :unauthorized} ->
      {:noreply,
       socket
       |> put_flash(:error, "You are not authorized to edit this goal")
       |> push_navigate(to: socket.assigns.patch)}

    {:error, %Ecto.Changeset{} = changeset} ->
      {:noreply, socket |> assign(:changeset, changeset) |> assign(:form, to_form(changeset))}
  end
end

defp save_goal(socket, :new, goal_params) do
  # Check subscription limits before creating
  current_user = socket.assigns.current_user
  current_goal_count = length(Goals.list_goals_by_user(current_user.id))

  if not can_create_goal?(current_user, current_goal_count) do
    limit = get_goal_limit(current_user)
    limit_text = case limit do
      :unlimited -> "unlimited"
      n -> "#{n}"
    end

    changeset = Goals.change_goal(socket.assigns.goal, goal_params)
    |> Ecto.Changeset.add_error(:base, "You can only create up to #{limit_text} goals...")

    {:noreply, socket |> assign(:changeset, changeset) |> assign(:form, to_form(changeset))}
  else
    goal_params = Map.put(goal_params, "user_id", socket.assigns.current_user_id)

    case Goals.create_goal(goal_params) do
      {:ok, _goal} ->
        {:noreply,
         socket
         |> put_flash(:info, "Goal created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(:changeset, changeset) |> assign(:form, to_form(changeset))}
    end
  end
end
```

**Pattern**:
- Dispatch based on `socket.assigns.action`
- Handle authorization errors with redirect
- Handle changeset errors by reassigning form
- Add business logic errors to changeset with `Ecto.Changeset.add_error/3`

## Render Pattern

### Form Component Template

```elixir
def render(assigns) do
  ~H"""
  <div>
    <.simple_form
      for={@form}
      id="goal-form"
      phx-target={@myself}
      phx-change="validate"
      phx-submit="save"
    >
      <.input field={@form[:title]} type="text" label="Goal Title" placeholder="..." required />

      <.input
        field={@form[:description]}
        type="textarea"
        label="Short Description"
        placeholder="..."
        rows="2"
      />

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <.input
          field={@form[:group_id]}
          type="select"
          label="Category"
          options={Enum.map(@goal_groups, &{&1.name, &1.id})}
          prompt="Select a category"
          required
        />

        <.input
          field={@form[:privacy]}
          type="select"
          label="Privacy"
          options={[
            {"Public - Anyone can see and subscribe", :public},
            {"Private - Only you can see", :private}
          ]}
          value={:public}
        />
      </div>

      <:actions>
        <.button phx-disable-with="Saving..." class="w-full">
          <%= if @action == :new, do: "Create Goal", else: "Update Goal" %>
        </.button>
      </:actions>
    </.simple_form>
  </div>
  """
end
```

**Key Template Patterns**:

1. **phx-target**: Always use `phx-target={@myself}` to route events to the component
2. **phx-change**: "validate" for real-time validation
3. **phx-submit**: "save" for form submission
4. **phx-disable-with**: Show loading state during submission
5. **Grid layouts**: Use Tailwind grid for form field arrangement

### Input Patterns

```elixir
# Text input
<.input field={@form[:title]} type="text" label="Goal Title" required />

# Textarea with custom rows
<.input field={@form[:description]} type="textarea" label="Description" rows="6" />

# Select with static options
<.input
  field={@form[:privacy]}
  type="select"
  label="Privacy"
  options={[{"Public", :public}, {"Private", :private}]}
/>

# Select with dynamic options
<.input
  field={@form[:group_id]}
  type="select"
  label="Category"
  options={Enum.map(@goal_groups, &{&1.name, &1.id})}
  prompt="Select a category"
/>

# Datetime input
<.input field={@form[:target_date]} type="datetime-local" label="Target Date" />

# Number input with constraints
<.input
  field={@form[:progress]}
  type="number"
  label="Progress %"
  min="0"
  max="100"
  value="0"
/>
```

## Using LiveComponent from Parent

### From LiveView

```elixir
<.live_component
  module={HeadsUpWeb.GoalLive.FormComponent}
  id="create-goal"
  action={:new}
  goal={%HeadsUp.Goal{}}
  current_user_id={@current_user_id}
  current_user={@current_user}
  goal_groups={@goal_groups}
  patch={~p"/my-goals"}
/>
```

### In Modal Context

```elixir
<%= if @show_create_form do %>
  <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
    <div class="bg-white rounded-lg p-6 max-w-2xl w-full mx-4">
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-xl font-semibold">Create New Goal</h2>
        <button phx-click="hide_create_form" class="text-gray-500 hover:text-gray-700">
          <!-- Close icon -->
        </button>
      </div>

      <.live_component
        module={HeadsUpWeb.GoalLive.FormComponent}
        id="create-goal"
        action={:new}
        goal={%HeadsUp.Goal{}}
        current_user_id={@current_user_id}
        goal_groups={@goal_groups}
        patch={~p"/my-goals"}
      />
    </div>
  </div>
<% end %>
```

**Pattern**: Modal wrapper lives in parent LiveView, component handles only form logic.

## State Management

### Component-Local State

```elixir
# In update/2
socket
|> assign(assigns)                    # From parent
|> assign(:changeset, changeset)      # Component-local
|> assign(:form, to_form(changeset))  # Component-local
```

### Accessing Parent Assigns

All assigns passed to the component are available via `socket.assigns`:

```elixir
socket.assigns.goal
socket.assigns.action
socket.assigns.current_user_id
socket.assigns.current_user
socket.assigns.goal_groups
socket.assigns.patch
```

## Component ID Requirements

Every LiveComponent MUST have a unique `id`:

```elixir
# Static ID for singleton components
id="create-goal"
id="edit-goal"

# Dynamic ID for list items
id={"goal-form-#{goal.id}"}
```

**Pattern**: Use static IDs for page-level forms, dynamic IDs when rendering multiple instances.

## Targeting Events

Events within a LiveComponent must be targeted with `@myself`:

```elixir
<form phx-target={@myself} phx-submit="save">

<button phx-target={@myself} phx-click="validate">
```

Without `phx-target={@myself}`, events would bubble up to the parent LiveView.
