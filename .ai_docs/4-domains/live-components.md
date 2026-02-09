# LiveComponents - Domain Patterns

## Overview

LiveComponents in HeadsUp are stateful, reusable interactive UI components that manage their own state and communicate with parent LiveViews. They are used for complex UI elements like forms that need their own lifecycle.

## LiveComponent Files

| Component Module | File Path | Purpose |
|------------------|-----------|---------|
| `HeadsUpWeb.GoalLive.FormComponent` | `/lib/heads_up_web/live/goal_live/form_component.ex` | Goal creation/editing form |

## Module Structure

### Standard LiveComponent Pattern

```elixir
# File: /lib/heads_up_web/live/goal_live/form_component.ex
defmodule HeadsUpWeb.GoalLive.FormComponent do
  use HeadsUpWeb, :live_component
  alias HeadsUp.Goals
  import HeadsUpWeb.Helpers.SubscriptionHelper

  def update(%{goal: goal} = assigns, socket) do
    # ...
  end

  def handle_event("validate", %{"goal" => goal_params}, socket) do
    # ...
  end

  def handle_event("save", %{"goal" => goal_params}, socket) do
    # ...
  end

  def render(assigns) do
    ~H"""
    <!-- Template -->
    """
  end
end
```

## Update Callback Pattern

The `update/2` callback receives assigns from the parent and initializes the component:

```elixir
# File: /lib/heads_up_web/live/goal_live/form_component.ex
def update(%{goal: goal} = assigns, socket) do
  changeset = Goals.change_goal(goal)

  {:ok,
   socket
   |> assign(assigns)
   |> assign(:changeset, changeset)
   |> assign(:form, to_form(changeset))}
end
```

## Form Handling Pattern

### Validate Event

```elixir
# File: /lib/heads_up_web/live/goal_live/form_component.ex
def handle_event("validate", %{"goal" => goal_params}, socket) do
  changeset =
    socket.assigns.goal
    |> Goals.change_goal(goal_params)
    |> Map.put(:action, :validate)

  {:noreply, socket |> assign(:changeset, changeset) |> assign(:form, to_form(changeset))}
end
```

### Save Event with Action Pattern

```elixir
# File: /lib/heads_up_web/live/goal_live/form_component.ex
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

    changeset = Goals.change_goal(socket.assigns.goal, goal_params)
    |> Ecto.Changeset.add_error(:base, "You can only create up to #{limit} goals...")

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

## Component Template Pattern

### Form with Core Components

```elixir
# File: /lib/heads_up_web/live/goal_live/form_component.ex
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
      <.input field={@form[:title]} type="text" label="Goal Title" placeholder="e.g., Run a Marathon" required />

      <.input
        field={@form[:description]}
        type="textarea"
        label="Short Description"
        placeholder="Brief description for goal cards..."
        rows="2"
      />

      <.input
        field={@form[:big_description]}
        type="textarea"
        label="Detailed Description (Optional)"
        placeholder="Write a detailed description..."
        rows="6"
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

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <.input
          field={@form[:target_date]}
          type="datetime-local"
          label="Target Date (Optional)"
        />

        <.input
          field={@form[:progress]}
          type="number"
          label="Initial Progress %"
          placeholder="0"
          min="0"
          max="100"
          value="0"
        />
      </div>

      <.input
        field={@form[:image_path]}
        type="text"
        label="Image URL (Optional)"
        placeholder="https://example.com/image.jpg"
      />

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

## Parent Communication Pattern

### Using phx-target

Events from the component are sent to itself using `@myself`:

```elixir
<.simple_form
  for={@form}
  id="goal-form"
  phx-target={@myself}
  phx-change="validate"
  phx-submit="save"
>
```

### Navigation to Parent

After successful operations, components navigate to parent routes:

```elixir
{:noreply,
 socket
 |> put_flash(:info, "Goal created successfully")
 |> push_navigate(to: socket.assigns.patch)}
```

## Component Usage in Parent LiveView

### Invoking LiveComponent

```elixir
# In parent LiveView template
<.live_component
  module={HeadsUpWeb.GoalLive.FormComponent}
  id="create-goal"
  action="new"
  goal={%HeadsUp.Goal{}}
  current_user_id={@current_user_id}
  goal_groups={@goal_groups}
  patch={~p"/my-goals"}
/>
```

### Required Attributes

LiveComponents must have a unique `id`:

```elixir
<.live_component
  module={HeadsUpWeb.GoalLive.FormComponent}
  id="create-goal"           # Required unique ID
  action="new"               # Action atom for save logic
  goal={%HeadsUp.Goal{}}     # Data to edit
  current_user_id={@current_user_id}  # User context
  goal_groups={@goal_groups}  # Related data
  patch={~p"/my-goals"}       # Return path after save
/>
```

## Error Handling Pattern

### Changeset Errors

```elixir
case Goals.create_goal(goal_params) do
  {:ok, _goal} ->
    {:noreply,
     socket
     |> put_flash(:info, "Goal created successfully")
     |> push_navigate(to: socket.assigns.patch)}

  {:error, %Ecto.Changeset{} = changeset} ->
    {:noreply, socket |> assign(:changeset, changeset) |> assign(:form, to_form(changeset))}
end
```

### Authorization Errors

```elixir
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
```

### Adding Custom Errors to Changeset

```elixir
if not can_create_goal?(current_user, current_goal_count) do
  limit = get_goal_limit(current_user)

  changeset = Goals.change_goal(socket.assigns.goal, goal_params)
  |> Ecto.Changeset.add_error(:base, "You can only create up to #{limit} goals with your current subscription")

  {:noreply, socket |> assign(:changeset, changeset) |> assign(:form, to_form(changeset))}
else
  # ... create goal
end
```

## Architectural Constraints

1. **Unique ID Required**: Components must have unique `id` assigns
2. **Update Callback**: Implement `update/2` to receive assigns from parent
3. **Self-Targeting**: Form events target `@myself` for component handling
4. **Parent Communication**: Use `push_navigate` or `send(self(), message)` to communicate with parent
5. **Isolated State**: Components manage their own state, don't modify parent assigns directly
