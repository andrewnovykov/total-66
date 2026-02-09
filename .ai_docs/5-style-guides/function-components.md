# Function Component Style Guide

This style guide documents the patterns and conventions used in HeadsUp function components.

## Module Structure

### Standard Component Module

```elixir
defmodule HeadsUpWeb.Components.GoalCard do
  use Phoenix.Component
  alias HeadsUp.Accounts

  # Component function
  def goal_card(assigns) do
    ~H"""
    <!-- Template -->
    """
  end

  # Private helpers
  defp status_class(:active), do: "bg-green-100 text-green-800"
end
```

**Pattern**: Use `Phoenix.Component`, alias only what's needed.

## File Organization

```
lib/heads_up_web/components/
  core_components.ex      # Standard Phoenix components
  layouts.ex              # Layout components
  goal_card.ex            # Domain-specific component
  commitment_chart.ex     # Feature-specific component
```

## Attribute Declarations

### Required and Optional Attributes

```elixir
attr :goal, :map, required: true
attr :show_category, :boolean, default: true
attr :show_creator, :boolean, default: true
attr :clickable, :boolean, default: true
attr :click_event, :string, default: "view_goal"
attr :current_user_id, :integer, default: nil
attr :show_privacy_info, :boolean, default: true
attr :can_view_details, :boolean, default: nil
```

**Pattern**:
- Declare all attributes with `attr`
- Use `:map` for complex data (structs)
- Provide sensible defaults
- Use `nil` default for computed/optional values

### Attribute Types

| Type | Use Case |
|------|----------|
| `:map` | Structs, complex data |
| `:boolean` | Feature flags |
| `:string` | Event names, text |
| `:integer` | IDs, counts |
| `:list` | Arrays of data |
| `:any` | Flexible/unknown types |

## Component Function Pattern

### Basic Component

```elixir
def goal_card(assigns) do
  ~H"""
  <div class="bg-white rounded-lg shadow-sm">
    <!-- Content -->
  </div>
  """
end
```

### Component with Preprocessing

```elixir
def goal_card(assigns) do
  # Compute derived values before template
  can_view_details = if assigns[:can_view_details] != nil do
    assigns.can_view_details
  else
    case assigns.goal.privacy do
      :public -> true
      :private -> assigns.current_user_id && assigns.current_user_id == assigns.goal.user_id
      :friends ->
        assigns.current_user_id && (assigns.current_user_id == assigns.goal.user_id ||
          Accounts.are_friends?(assigns.current_user_id, assigns.goal.user_id))
      _ -> true
    end
  end

  is_clickable = assigns.clickable && can_view_details

  # Reassign computed values
  assigns = assign(assigns, :can_view_details, can_view_details)
  assigns = assign(assigns, :is_clickable, is_clickable)

  ~H"""
  <div class={"card #{if @is_clickable, do: "cursor-pointer"}"}>
    <!-- Template uses @can_view_details, @is_clickable -->
  </div>
  """
end
```

**Pattern**: Compute complex values before template, reassign to makes them available.

## Commitment Chart Component

### Complex Data Processing

```elixir
def commitment_chart(assigns) do
  ~H"""
  <div class="bg-white border border-gray-200 rounded-xl">
    <!-- Header -->
    <div class="px-6 py-4 border-b">
      <div class="flex justify-between items-center">
        <h3 class="text-lg font-semibold">Activity Chart</h3>
        <div class="text-sm">{length(@chart_data)} days tracked</div>
      </div>
    </div>

    <!-- Chart Grid -->
    <div class="p-6">
      <div class="grid gap-[2px]" style="grid-template-rows: repeat(7, 12px); grid-template-columns: repeat(53, 12px);">
        <%= for day_data <- organize_chart_data(@chart_data) do %>
          <div
            class={"w-3 h-3 rounded-sm #{intensity_color(day_data.intensity)}"}
            title={"#{day_data.date}: #{day_data.activity_count} activities"}
          >
          </div>
        <% end %>
      </div>

      <!-- Stats Grid -->
      <div class="grid grid-cols-3 gap-4">
        <div class="bg-blue-50 rounded-lg p-4 text-center">
          <div class="text-2xl font-bold">{@activity_summary.total_xp}</div>
          <div class="text-sm">Total XP</div>
        </div>
        <!-- More stats -->
      </div>
    </div>
  </div>
  """
end
```

### Private Helper Functions

```elixir
defp intensity_color(0), do: "bg-gray-100"
defp intensity_color(1), do: "bg-blue-200"
defp intensity_color(2), do: "bg-blue-400"
defp intensity_color(3), do: "bg-blue-600"
defp intensity_color(4), do: "bg-blue-800"
defp intensity_color(_), do: "bg-blue-800"

defp organize_chart_data(chart_data) do
  first_date = List.first(chart_data) |> Map.get(:date, Date.utc_today())

  # Calculate week alignment
  days_from_sunday = Date.day_of_week(first_date, :sunday) - 1
  start_date = Date.add(first_date, -days_from_sunday)

  # Create lookup map
  data_map = Map.new(chart_data, fn day -> {day.date, day} end)

  # Generate 53 weeks x 7 days
  for week <- 0..52, day_of_week <- 0..6 do
    date = Date.add(start_date, week * 7 + day_of_week)
    Map.get(data_map, date, %{date: date, activity_count: 0, xp_total: 0, intensity: 0})
  end
end

defp get_streak(chart_data) do
  chart_data
  |> Enum.reverse()
  |> Enum.reduce_while(0, fn day, acc ->
    if day.activity_count > 0 do
      {:cont, acc + 1}
    else
      {:halt, acc}
    end
  end)
end
```

**Pattern**: Use `Enum.reduce_while` for early-terminating calculations like streaks.

## CSS Class Helpers

### Function Clause Matching

```elixir
defp status_class(:active), do: "bg-green-100 text-green-800"
defp status_class(:completed), do: "bg-blue-100 text-blue-800"
defp status_class(:paused), do: "bg-yellow-100 text-yellow-800"
defp status_class(:cancelled), do: "bg-red-100 text-red-800"
defp status_class(_), do: "bg-gray-100 text-gray-800"

defp privacy_class(:public), do: "bg-green-100 text-green-700"
defp privacy_class(:friends), do: "bg-blue-100 text-blue-700"
defp privacy_class(:private), do: "bg-gray-100 text-gray-700"
defp privacy_class(_), do: "bg-gray-100 text-gray-700"
```

**Pattern**: Always include catch-all clause `_` as last match.

## Template Patterns

### Dynamic Class Binding

```elixir
class={"bg-white rounded-lg #{if @is_clickable, do: "cursor-pointer hover:border-blue-300"}"}

class={"px-2 py-1 rounded-full #{status_class(@goal.status)}"}
```

### Conditional Rendering

```elixir
<%= if @can_view_details do %>
  <p class="text-sm"><%= @goal.description %></p>
<% else %>
  <p class="text-gray-400 italic">This goal's details are private</p>
<% end %>
```

### Case Matching in Templates

```elixir
<%= case @goal.privacy do %>
  <% :public -> %> Public
  <% :friends -> %> Friends Only
  <% _ -> %> Private
<% end %>
```

### Event Handlers

```elixir
<div
  phx-click={if @is_clickable, do: @click_event, else: nil}
  phx-value-goal-id={@goal.id}
>
```

**Pattern**: Use `nil` to disable click handlers conditionally.

## Using Function Components

### From LiveView

```elixir
# Import the component module
import HeadsUpWeb.Components.GoalCard

# Use in template
<.goal_card
  goal={goal}
  show_category={true}
  show_creator={false}
  clickable={true}
  current_user_id={@current_user_id}
/>
```

### With :for Iteration

```elixir
<div :for={goal <- @user_goals}>
  <.goal_card
    goal={goal}
    show_category={true}
    show_creator={false}
    clickable={true}
    current_user_id={if @current_user, do: @current_user.id, else: nil}
  />
</div>
```

## Component Communication

### Event Delegation

Function components don't handle events directly. Events bubble up to the parent LiveView:

```elixir
# In component template
<button
  phx-click="toggle_like"
  phx-value-goal-id={@goal.id}
>
  Like
</button>

# Handled in parent LiveView
def handle_event("toggle_like", %{"goal-id" => goal_id}, socket) do
  # Handle event
end
```

### Navigation Links

```elixir
<div phx-click="view_goal" phx-value-goal-id={@goal.id} class="cursor-pointer">
  <!-- Click triggers event in parent -->
</div>

<div phx-click="view_user" phx-value-user-id={@goal.user.id} class="cursor-pointer">
  <!-- Navigate to user profile -->
</div>
```

## Accessibility Patterns

### Title Attributes for Tooltips

```elixir
<div
  class="w-3 h-3 rounded-sm"
  title={"#{day_data.date}: #{day_data.activity_count} activities, #{day_data.xp_total} XP"}
>
</div>
```

### Semantic HTML

```elixir
<h3 class="text-lg font-semibold"><%= @goal.title %></h3>
<p class="text-sm"><%= @goal.description %></p>
```

## Slot Usage (from core_components.ex)

For more complex components that need content injection:

```elixir
slot :actions

def simple_form(assigns) do
  ~H"""
  <form>
    <!-- Form fields -->
    <div class="mt-4">
      <%= render_slot(@actions) %>
    </div>
  </form>
  """
end

# Usage
<.simple_form for={@form} phx-submit="save">
  <.input field={@form[:name]} />
  <:actions>
    <.button>Save</.button>
  </:actions>
</.simple_form>
```
