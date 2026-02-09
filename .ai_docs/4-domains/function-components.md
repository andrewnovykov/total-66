# Function Components - Domain Patterns

## Overview

Function components in HeadsUp are stateless, reusable UI building blocks defined using the `Phoenix.Component` module. They use the `attr` and `slot` macros for declarative attribute definitions and the `~H` sigil for HEEx templates.

## Component Files

| Component Module | File Path | Purpose |
|------------------|-----------|---------|
| `HeadsUpWeb.CoreComponents` | `/lib/heads_up_web/components/core_components.ex` | Standard Phoenix UI components |
| `HeadsUpWeb.Components.GoalCard` | `/lib/heads_up_web/components/goal_card.ex` | Goal display card |
| `HeadsUpWeb.Components.CommitmentChart` | `/lib/heads_up_web/components/commitment_chart.ex` | Activity visualization chart |

## Module Structure

### Custom Component Module

```elixir
# File: /lib/heads_up_web/components/goal_card.ex
defmodule HeadsUpWeb.Components.GoalCard do
  use Phoenix.Component
  alias HeadsUp.Accounts

  attr :goal, :map, required: true
  attr :show_category, :boolean, default: true
  attr :show_creator, :boolean, default: true
  attr :clickable, :boolean, default: true
  attr :click_event, :string, default: "view_goal"
  attr :current_user_id, :integer, default: nil
  attr :show_privacy_info, :boolean, default: true
  attr :can_view_details, :boolean, default: nil

  def goal_card(assigns) do
    # Pre-processing logic
    # ...
    ~H"""
    <!-- Template -->
    """
  end
end
```

### Core Components Module

```elixir
# File: /lib/heads_up_web/components/core_components.ex
defmodule HeadsUpWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  import HeadsUpWeb.Gettext

  # Component definitions...
end
```

## Attribute Declaration Pattern

### Using attr Macro

```elixir
# File: /lib/heads_up_web/components/goal_card.ex
attr :goal, :map, required: true
attr :show_category, :boolean, default: true
attr :show_creator, :boolean, default: true
attr :clickable, :boolean, default: true
attr :click_event, :string, default: "view_goal"
attr :current_user_id, :integer, default: nil
attr :show_privacy_info, :boolean, default: true
attr :can_view_details, :boolean, default: nil

def goal_card(assigns) do
  # ...
end
```

### Core Component Attributes

```elixir
# File: /lib/heads_up_web/components/core_components.ex

# Modal component
attr :id, :string, required: true
attr :show, :boolean, default: false
attr :on_cancel, JS, default: %JS{}
slot :inner_block, required: true

def modal(assigns) do
  # ...
end

# Flash component
attr :id, :string, doc: "the optional id of flash container"
attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
attr :title, :string, default: nil
attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

slot :inner_block, doc: "the optional inner block that renders the flash message"

def flash(assigns) do
  # ...
end

# Simple form component
attr :for, :any, required: true, doc: "the data structure for the form"
attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

attr :rest, :global,
  include: ~w(autocomplete name rel action enctype method novalidate target multipart),
  doc: "the arbitrary HTML attributes to apply to the form tag"

slot :inner_block, required: true
slot :actions, doc: "the slot for form actions, such as a submit button"

def simple_form(assigns) do
  # ...
end
```

## Slot Pattern

### Using slot Macro

```elixir
# File: /lib/heads_up_web/components/core_components.ex

slot :inner_block, required: true
slot :actions, doc: "the slot for form actions, such as a submit button"

def simple_form(assigns) do
  ~H"""
  <.form :let={f} for={@for} as={@as} {@rest}>
    <div class="mt-10 space-y-8 bg-white">
      <%= render_slot(@inner_block, f) %>
      <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
        <%= render_slot(action, f) %>
      </div>
    </div>
  </.form>
  """
end
```

### Rendering Slots

```elixir
# render_slot for required content
<%= render_slot(@inner_block) %>

# render_slot with let binding
<%= render_slot(@inner_block, f) %>

# Conditional slot rendering with :for
<div :for={action <- @actions}>
  <%= render_slot(action) %>
</div>
```

## Pre-Processing Pattern

### Computed Assigns

```elixir
# File: /lib/heads_up_web/components/goal_card.ex
def goal_card(assigns) do
  # Determine if user can view goal details based on privacy
  can_view_details = if assigns[:can_view_details] != nil do
    assigns.can_view_details
  else
    case assigns.goal.privacy do
      :public -> true
      :private -> assigns.current_user_id && assigns.current_user_id == assigns.goal.user_id
      :friends ->
        assigns.current_user_id && (assigns.current_user_id == assigns.goal.user_id ||
          (assigns.current_user_id && Accounts.are_friends?(assigns.current_user_id, assigns.goal.user_id)))
      _ -> true  # Default to public behavior
    end
  end

  # Can only click if can view details
  is_clickable = assigns.clickable && can_view_details

  assigns = assign(assigns, :can_view_details, can_view_details)
  assigns = assign(assigns, :is_clickable, is_clickable)

  ~H"""
  <!-- Template uses @can_view_details and @is_clickable -->
  """
end
```

## Template Patterns

### Conditional Rendering

```elixir
# File: /lib/heads_up_web/components/goal_card.ex
~H"""
<div class="bg-white rounded-lg shadow-sm">
  <%= if @can_view_details do %>
    <%= if @goal.image_path do %>
      <img src={@goal.image_path} alt={@goal.title} class="w-full h-full object-cover" />
    <% else %>
      <div class="w-full h-full bg-gradient-to-r from-blue-400 to-purple-500">
        <!-- Default image -->
      </div>
    <% end %>
  <% else %>
    <div class="w-full h-full bg-gray-400 flex items-center justify-center">
      <!-- Privacy message -->
    </div>
  <% end %>
</div>
"""
```

### Case Expression in Template

```elixir
# File: /lib/heads_up_web/components/goal_card.ex
~H"""
<span class={"px-2 py-1 rounded-full text-xs font-medium #{privacy_class(@goal.privacy)}"}>
  <%= case @goal.privacy do %>
    <% :public -> %>
      🌐 Public
    <% :friends -> %>
      👥 Friends
    <% _ -> %>
      🔒 Private
  <% end %>
</span>
"""
```

### Dynamic Classes

```elixir
# File: /lib/heads_up_web/components/goal_card.ex
~H"""
<div class={"bg-white rounded-lg shadow-sm #{if @is_clickable, do: "cursor-pointer hover:border-blue-300", else: ""}"}>
  <!-- content -->
</div>
"""
```

### Event Bindings

```elixir
# File: /lib/heads_up_web/components/goal_card.ex
~H"""
<div
  phx-click={if @is_clickable, do: @click_event, else: nil}
  phx-value-goal-id={@goal.id}
>
  <!-- clickable content -->
</div>

<button
  phx-click="toggle_like"
  phx-value-goal-id={@goal.id}
  class="flex items-center space-x-2 px-3 py-2 rounded-lg"
>
  <span><%= Map.get(@goal, :like_count, 0) %></span>
</button>
"""
```

## Helper Functions Pattern

### Private CSS Class Helpers

```elixir
# File: /lib/heads_up_web/components/goal_card.ex
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

### Commitment Chart Helpers

```elixir
# File: /lib/heads_up_web/components/commitment_chart.ex
defp intensity_color(0), do: "bg-gray-100"
defp intensity_color(1), do: "bg-blue-200"
defp intensity_color(2), do: "bg-blue-400"
defp intensity_color(3), do: "bg-blue-600"
defp intensity_color(4), do: "bg-blue-800"
defp intensity_color(_), do: "bg-blue-800"

defp organize_chart_data(chart_data) do
  # Complex data transformation for chart layout
  first_date = List.first(chart_data) |> Map.get(:date, Date.utc_today())
  days_from_sunday = Date.day_of_week(first_date, :sunday) - 1
  start_date = Date.add(first_date, -days_from_sunday)
  data_map = Map.new(chart_data, fn day -> {day.date, day} end)

  for week <- 0..52, day_of_week <- 0..6 do
    date = Date.add(start_date, week * 7 + day_of_week)

    case Map.get(data_map, date) do
      nil ->
        %{date: date, activity_count: 0, xp_total: 0, intensity: 0}
      existing_data ->
        existing_data
    end
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

## Commitment Chart Component

```elixir
# File: /lib/heads_up_web/components/commitment_chart.ex
defmodule HeadsUpWeb.Components.CommitmentChart do
  use Phoenix.Component

  def commitment_chart(assigns) do
    ~H"""
    <div class="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden">
      <!-- Header -->
      <div class="px-6 py-4 border-b border-gray-100 bg-gray-50">
        <div class="flex justify-between items-center">
          <div>
            <h3 class="text-lg font-semibold text-gray-900">Activity Chart</h3>
            <p class="text-sm text-gray-600 mt-1">Your commitment over the past year</p>
          </div>
          <div class="text-right">
            <div class="text-sm font-medium text-gray-700">{length(@chart_data)}</div>
            <div class="text-xs text-gray-500">days tracked</div>
          </div>
        </div>
      </div>

      <!-- Chart Grid -->
      <div class="p-6">
        <div class="grid gap-[2px]" style="grid-template-rows: repeat(7, 12px); grid-template-columns: repeat(53, 12px); grid-auto-flow: column;">
          <%= for day_data <- organize_chart_data(@chart_data) do %>
            <div
              class={"w-3 h-3 rounded-sm transition-all duration-200 hover:scale-110 cursor-pointer #{intensity_color(day_data.intensity)}"}
              title={"#{day_data.date}: #{day_data.activity_count} activities, #{day_data.xp_total} XP"}
            >
            </div>
          <% end %>
        </div>

        <!-- Stats Grid -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div class="bg-gradient-to-r from-blue-50 to-blue-100 rounded-lg p-4 text-center">
            <div class="text-2xl font-bold text-blue-700">{@activity_summary.total_xp}</div>
            <div class="text-sm text-blue-600 font-medium">Total XP</div>
          </div>

          <div class="bg-gradient-to-r from-indigo-50 to-indigo-100 rounded-lg p-4 text-center">
            <div class="text-2xl font-bold text-indigo-700">{@user_level}</div>
            <div class="text-sm text-indigo-600 font-medium">Current Level</div>
          </div>

          <div class="bg-gradient-to-r from-sky-50 to-sky-100 rounded-lg p-4 text-center">
            <div class="text-2xl font-bold text-sky-700">{get_streak(@chart_data)}</div>
            <div class="text-sm text-sky-600 font-medium">Current Streak</div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
```

## Component Usage

### Importing Components

```elixir
# In LiveView module
import HeadsUpWeb.Components.GoalCard
import HeadsUpWeb.Components.CommitmentChart
```

### Using in Templates

```elixir
# Goal card usage
<.goal_card
  goal={goal}
  show_category={true}
  show_creator={false}
  clickable={true}
  current_user_id={if @current_user, do: @current_user.id, else: nil}
/>

# Commitment chart usage
<.commitment_chart
  chart_data={@chart_data}
  activity_summary={@activity_summary}
  user={@user}
  user_level={@user_level}
/>
```

### Core Component Usage

```elixir
# Modal
<.modal id="confirm-modal">
  This is a modal.
</.modal>

# Flash
<.flash kind={:info} flash={@flash} />
<.flash kind={:error} flash={@flash} />

# Simple form
<.simple_form for={@form} phx-change="validate" phx-submit="save">
  <.input field={@form[:email]} label="Email"/>
  <.input field={@form[:username]} label="Username" />
  <:actions>
    <.button>Save</.button>
  </:actions>
</.simple_form>
```

## Architectural Constraints

1. **No State**: Function components are pure - no assigns updates
2. **Reusable**: Components should be generic and reusable across pages
3. **Attr Declarations**: Use `attr` macro to declare component attributes with types
4. **Slot Support**: Use `slot` macro for content injection
5. **HEEx Sigil**: Use `~H` sigil for template markup
6. **Private Helpers**: Use private functions for CSS classes and data transformations
