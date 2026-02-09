# Templates (HEEx) Style Guide

This style guide documents the patterns and conventions used in HeadsUp HEEx template files.

## File Organization

```
lib/heads_up_web/
  components/layouts/
    app.html.heex        # Main application layout
    root.html.heex       # Root HTML document
  controllers/
    page_html/
      home.html.heex     # Controller-rendered templates
```

## Root Layout Pattern

### HTML Document Structure

```heex
<!DOCTYPE html>
<html lang="en" class="[scrollbar-gutter:stable]">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="csrf-token" content={get_csrf_token()} />
    <.live_title suffix=" · Phoenix Framework">
      {assigns[:page_title] || "HeadsUp"}
    </.live_title>

    <!-- External fonts -->
    <link
      rel="stylesheet"
      as="style"
      onload="this.rel='stylesheet'"
      href="https://fonts.googleapis.com/css2?..."
    />

    <!-- Scripts -->
    <script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}></script>
  </head>
  <body class="bg-white">
    <div class="relative flex size-full min-h-screen flex-col">
      <div class="layout-container flex h-full grow flex-col">
        {@inner_content}
      </div>
    </div>
  </body>
</html>
```

**Pattern**:
- Use `[scrollbar-gutter:stable]` for consistent scrollbar behavior
- Load fonts with async pattern (`onload="this.rel='stylesheet'"`)
- Use `phx-track-static` for Phoenix static asset tracking
- Use `{assigns[:page_title] || "Default"}` for safe title access

## App Layout Pattern

### Navigation with Authentication State

```heex
<header class="flex items-center justify-between">
  <!-- Logo and navigation links -->
  <div class="flex items-center gap-8">
    <a href="/">Home</a>
    <a href="/goals">Goals</a>

    <%= if @current_user do %>
      <a href="/connections">Connections</a>
      <a href="/feed">Feed</a>
    <% end %>

    <%= if @current_user && @current_user.role == "admin" do %>
      <a href="/admin/categories">Admin</a>
    <% end %>
  </div>
</header>
```

**Pattern**: Use conditional rendering for role-based navigation.

### Dynamic Business Logic in Templates

```heex
<% user_goal_count = length(HeadsUp.Goals.list_goals_by_user(@current_user.id))

can_create =
  HeadsUpWeb.Helpers.SubscriptionHelper.can_create_goal?(@current_user, user_goal_count) %>

<%= if can_create do %>
  <.link navigate={~p"/goals/new"} class="bg-[#e7edf4] text-[#0d141c]">
    Create Goal
  </.link>
<% else %>
  <.link navigate={~p"/my-goals"} class="bg-gray-200 text-gray-400" title="Upgrade to create more goals">
    Create Goal
  </.link>
<% end %>
```

**Pattern**: Compute values at template start, use for conditional rendering.

### User Dropdown with Alpine.js

```heex
<div class="relative" x-data="{ open: false }">
  <button @click="open = !open" class="flex items-center gap-2 cursor-pointer">
    <div
      class="bg-center bg-no-repeat aspect-square bg-cover rounded-full size-10"
      style={"background-image: url(\"#{HeadsUpWeb.Helpers.AvatarHelper.get_user_avatar(@current_user)}\");"}
    >
    </div>
    <span>{@current_user.email}</span>
    <!-- Chevron icon -->
  </button>

  <div
    x-show="open"
    @click.away="open = false"
    x-transition:enter="transition ease-out duration-100"
    x-transition:enter-start="transform opacity-0 scale-95"
    x-transition:enter-end="transform opacity-100 scale-100"
    class="absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-lg"
  >
    <!-- Dropdown items -->
  </div>
</div>
```

**Pattern**: Use Alpine.js for interactive dropdowns with `x-data`, `x-show`, `@click.away`.

### Dynamic Style Attribute

```heex
<div
  class="bg-center bg-no-repeat aspect-square bg-cover rounded-full"
  style={"background-image: url(\"#{get_avatar_url(@user)}\");"}
>
</div>
```

**Pattern**: Use interpolated style attribute for dynamic background images.

## Flash Messages

```heex
<div class="mx-auto max-w-2xl">
  <.flash_group flash={@flash} />
</div>
{@inner_content}
```

**Pattern**: Place flash messages above main content with constrained width.

## Page Template Pattern

### Section Structure

```heex
<h2 class="text-[#0d141c] text-[22px] font-bold leading-tight tracking-[-0.015em] px-4 pb-3 pt-5">
  Trending Goals
</h2>
<div class="flex overflow-y-auto [-ms-scrollbar-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
  <div class="flex items-stretch p-4 gap-3">
    <%= if Enum.empty?(@trending_goals) do %>
      <p class="text-[#49739c] text-sm">No trending goals yet. Be the first to create one!</p>
    <% else %>
      <%= for goal <- @trending_goals do %>
        <!-- Goal card -->
      <% end %>
    <% end %>
  </div>
</div>
```

**Pattern**:
- Section heading with consistent typography
- Horizontal scroll container with hidden scrollbars
- Empty state handling
- List iteration with `for` comprehension

### Hidden Scrollbar Pattern

```heex
<div class="flex overflow-y-auto [-ms-scrollbar-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
```

**Pattern**: Hide scrollbars across browsers using Tailwind arbitrary values.

### Grid Layout

```heex
<div class="grid grid-cols-[repeat(auto-fit,minmax(158px,1fr))] gap-3 p-4">
  <%= for group <- @popular_groups do %>
    <!-- Grid item -->
  <% end %>
</div>
```

**Pattern**: Use CSS Grid with auto-fit for responsive layouts.

## Card Patterns

### Goal Card

```heex
<.link navigate={~p"/goals/#{goal.id}"} class="flex h-full flex-1 flex-col gap-4 rounded-lg min-w-60 hover:opacity-90 transition-opacity">
  <div class="w-full bg-center bg-no-repeat aspect-video bg-cover rounded-xl"
       style={"background-image: url('#{goal.image_path || get_default_goal_image()}');"}
  >
  </div>
  <div>
    <p class="text-[#0d141c] text-base font-medium">{goal.title}</p>
    <p class="text-[#49739c] text-sm">
      By <%= goal.user.name || goal.user.user_name || "Anonymous" %> in <%= goal.group.name %>
    </p>
  </div>
</.link>
```

**Pattern**: Clickable card with image, fallback handling, and cascading nil-safe text.

### User Card

```heex
<.link navigate={~p"/people/#{user.user_name || user.id}"} class="flex flex-col text-center min-w-32">
  <div class="bg-center bg-no-repeat aspect-square bg-cover rounded-full self-center w-full"
       style={"background-image: url('#{user.image_path || get_default_user_image()}');"}
  >
  </div>
  <div>
    <p class="text-base font-medium"><%= user.name || user.user_name || "Anonymous" %></p>
    <p class="text-sm">
      Level <%= user.level %>
      <%= if user.latest_achievement do %>
        <br/>Achieved: <%= user.latest_achievement %>
      <% end %>
    </p>
  </div>
</.link>
```

**Pattern**: Use username with ID fallback in URL, handle optional fields.

## Link Patterns

### Navigation Link

```heex
<.link navigate={~p"/goals/#{goal.id}"} class="hover:opacity-90 transition-opacity">
  <!-- Content -->
</.link>
```

**Pattern**: Use `navigate` for LiveView navigation, `href` for regular links.

### Dropdown Link with Icon

```heex
<.link
  href={~p"/people/#{@current_user.user_name}"}
  class="flex items-center px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
>
  <svg class="w-4 h-4 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <!-- Icon path -->
  </svg>
  View Profile
</.link>
```

### Logout Link with Method

```heex
<.link
  href={~p"/users/log_out"}
  method="delete"
  class="flex items-center px-4 py-2 text-sm"
>
  Log out
</.link>
```

**Pattern**: Use `method="delete"` for logout actions.

## Conditional Rendering

### Authentication-Based Content

```heex
<%= if @current_user do %>
  <!-- Authenticated user UI -->
<% else %>
  <!-- Guest user UI -->
<% end %>
```

### Role-Based Content

```heex
<%= if @current_user && @current_user.role == "admin" do %>
  <!-- Admin-only content -->
<% end %>
```

### Empty State

```heex
<%= if Enum.empty?(@items) do %>
  <p class="text-gray-500">No items found.</p>
<% else %>
  <%= for item <- @items do %>
    <!-- Item rendering -->
  <% end %>
<% end %>
```

### Optional Field Display

```heex
<%= if user.latest_achievement do %>
  <br/>Achieved: <%= user.latest_achievement %>
<% end %>
```

## Plural Handling

```heex
<p><%= group.goal_count %> <%= if group.goal_count == 1, do: "goal", else: "goals" %></p>
```

**Pattern**: Inline conditional for singular/plural text.

## CSS Class Patterns

### Tailwind Utility Classes

```heex
class="text-[#0d141c] text-[22px] font-bold leading-tight tracking-[-0.015em] px-4 pb-3 pt-5"
```

**Pattern**: Use custom color values with bracket notation `[#0d141c]`.

### Hover Effects

```heex
class="hover:opacity-90 transition-opacity"
class="hover:bg-gray-100"
class="hover:bg-[#d1dde8]"
```

### Aspect Ratio

```heex
class="aspect-video"   <!-- 16:9 -->
class="aspect-square"  <!-- 1:1 -->
```

### Size Utilities

```heex
class="size-10"  <!-- width: 10, height: 10 -->
class="size-4"   <!-- width: 4, height: 4 -->
```

## SVG Icons

### Inline SVG Pattern

```heex
<svg xmlns="http://www.w3.org/2000/svg" width="20px" height="20px" fill="currentColor" viewBox="0 0 256 256">
  <path d="..."></path>
</svg>
```

**Pattern**: Use `fill="currentColor"` to inherit text color.

### Icon with Data Attributes

```heex
<div class="text-[#0d141c]" data-icon="Plus" data-size="20px" data-weight="regular">
  <svg><!-- icon --></svg>
</div>
```

**Pattern**: Use data attributes for icon metadata.

## Comments

```heex
<%!-- Authenticated user UI --%>
<!-- Home page content -->
```

**Pattern**: Use `<%!-- --%>` for EEx comments (not rendered), `<!-- -->` for HTML comments (rendered).
