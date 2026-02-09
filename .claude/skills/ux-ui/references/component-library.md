# HeadsUp Reusable Component Library

All components live in `lib/heads_up_web/components/` and follow Phoenix function component conventions.

## Table of Contents

1. [Avatar](#avatar)
2. [Card](#card)
3. [PostCard](#post-card)
4. [Tag](#tag)
5. [StatBadge](#stat-badge)
6. [SidebarCard](#sidebar-card)
7. [CategoryCard](#category-card)
8. [EmptyState](#empty-state)
9. [Skeleton](#skeleton)
10. [EngagementBar](#engagement-bar)
11. [ProgressBar](#progress-bar)
12. [SectionHeader](#section-header)
13. [UserMiniCard](#user-mini-card)
14. [BottomNav](#bottom-nav)
15. [StatusBadge](#status-badge)
16. [ThreeColumnLayout](#three-column-layout)

---

## Avatar

File: `avatar.ex`

```elixir
defmodule HeadsUpWeb.Components.Avatar do
  use Phoenix.Component

  attr :src, :string, default: nil
  attr :name, :string, required: true
  attr :size, :atom, values: [:xs, :sm, :md, :lg, :xl], default: :md
  attr :class, :string, default: ""
  attr :online, :boolean, default: false

  def avatar(assigns) do
    ~H"""
    <div class={["relative inline-flex shrink-0", size_class(@size), @class]}>
      <img
        :if={@src}
        src={@src}
        alt={@name}
        class="rounded-full object-cover w-full h-full"
      />
      <div
        :if={!@src}
        class="rounded-full bg-gradient-to-br from-indigo-400 to-pink-400 flex items-center justify-center w-full h-full"
      >
        <span class={["font-semibold text-white", initials_size(@size)]}>
          <%= initials(@name) %>
        </span>
      </div>
      <span
        :if={@online}
        class="absolute bottom-0 right-0 w-3 h-3 bg-green-400 border-2 border-white rounded-full"
      />
    </div>
    """
  end

  defp size_class(:xs), do: "w-6 h-6"
  defp size_class(:sm), do: "w-8 h-8"
  defp size_class(:md), do: "w-10 h-10"
  defp size_class(:lg), do: "w-14 h-14"
  defp size_class(:xl), do: "w-20 h-20"

  defp initials_size(:xs), do: "text-[10px]"
  defp initials_size(:sm), do: "text-xs"
  defp initials_size(:md), do: "text-sm"
  defp initials_size(:lg), do: "text-lg"
  defp initials_size(:xl), do: "text-2xl"

  defp initials(name) do
    name
    |> String.split(" ")
    |> Enum.take(2)
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
  end
end
```

---

## Card

File: `card.ex`

Base card wrapper with the "Soft Modern" aesthetic.

```elixir
defmodule HeadsUpWeb.Components.Card do
  use Phoenix.Component

  attr :class, :string, default: ""
  attr :hover, :boolean, default: false
  attr :padding, :atom, values: [:none, :sm, :md, :lg], default: :md
  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <div class={[
      "bg-white rounded-3xl",
      "shadow-[0_4px_20px_rgba(0,0,0,0.05)]",
      @hover && "hover:shadow-[0_10px_25px_rgba(0,0,0,0.08)] transition-shadow duration-200",
      padding_class(@padding),
      @class
    ]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp padding_class(:none), do: ""
  defp padding_class(:sm), do: "p-3"
  defp padding_class(:md), do: "p-6"
  defp padding_class(:lg), do: "p-8"
end
```

---

## Post Card

File: `post_card.ex`

Social feed post card with avatar, content, media, tags, and engagement.

```elixir
attr :user_name, :string, required: true
attr :user_avatar, :string, default: nil
attr :timestamp, :string, default: nil
attr :content, :string, required: true
attr :image, :string, default: nil
attr :tags, :list, default: []
attr :likes_count, :integer, default: 0
attr :comments_count, :integer, default: 0
attr :is_liked, :boolean, default: false
slot :actions
slot :menu

def post_card(assigns) do
  ~H"""
  <.card hover>
    <div class="flex items-start gap-3">
      <.avatar name={@user_name} src={@user_avatar} size={:md} />
      <div class="flex-1 min-w-0">
        <div class="flex items-center justify-between">
          <div>
            <span class="font-semibold text-gray-900 text-sm"><%= @user_name %></span>
            <span :if={@timestamp} class="text-gray-400 text-xs ml-2"><%= @timestamp %></span>
          </div>
          <%= render_slot(@menu) %>
        </div>
        <p class="text-gray-700 text-sm mt-1 leading-relaxed"><%= @content %></p>
      </div>
    </div>

    <img :if={@image} src={@image} class="w-full rounded-2xl mt-3 object-cover max-h-80" />

    <div :if={@tags != []} class="flex flex-wrap gap-2 mt-3">
      <.tag :for={tag <- @tags} label={tag} />
    </div>

    <.engagement_bar
      likes_count={@likes_count}
      comments_count={@comments_count}
      is_liked={@is_liked}
    />

    <%= render_slot(@actions) %>
  </.card>
  """
end
```

---

## Tag

File: `tag.ex`

Pastel-colored tag/badge with predefined color variants.

```elixir
attr :label, :string, required: true
attr :color, :atom, values: [:blue, :green, :red, :yellow, :purple, :pink, :gray], default: :blue
attr :size, :atom, values: [:sm, :md], default: :sm

def tag(assigns) do
  ~H"""
  <span class={[
    "inline-flex items-center font-medium rounded-full",
    color_class(@color),
    size_class(@size)
  ]}>
    <%= @label %>
  </span>
  """
end

defp color_class(:blue), do: "bg-blue-100 text-blue-800"
defp color_class(:green), do: "bg-green-100 text-green-800"
defp color_class(:red), do: "bg-red-100 text-red-800"
defp color_class(:yellow), do: "bg-amber-100 text-amber-800"
defp color_class(:purple), do: "bg-purple-100 text-purple-800"
defp color_class(:pink), do: "bg-pink-100 text-pink-800"
defp color_class(:gray), do: "bg-gray-100 text-gray-800"

defp size_class(:sm), do: "px-2.5 py-0.5 text-xs"
defp size_class(:md), do: "px-3 py-1 text-sm"
```

---

## StatBadge

File: `stat_badge.ex`

Numeric stat display with label.

```elixir
attr :value, :any, required: true
attr :label, :string, required: true
attr :icon, :string, default: nil

def stat_badge(assigns) do
  ~H"""
  <div class="flex flex-col items-center">
    <span class="text-xl font-bold text-gray-900"><%= @value %></span>
    <span class="text-xs text-gray-500"><%= @label %></span>
  </div>
  """
end
```

---

## SidebarCard

File: `sidebar_card.ex`

Right sidebar suggestion card (popular posts, friend suggestions).

```elixir
attr :title, :string, required: true
attr :subtitle, :string, default: nil
attr :image, :string, default: nil
attr :avatar_name, :string, default: nil
attr :link, :string, default: nil
slot :action

def sidebar_card(assigns) do
  ~H"""
  <div class="flex items-start gap-3 p-3 rounded-2xl hover:bg-gray-50 transition-colors">
    <.avatar :if={@avatar_name} name={@avatar_name} src={@image} size={:sm} />
    <img :if={@image && !@avatar_name} src={@image} class="w-10 h-10 rounded-xl object-cover" />
    <div class="flex-1 min-w-0">
      <p class="text-sm font-semibold text-gray-900 truncate"><%= @title %></p>
      <p :if={@subtitle} class="text-xs text-gray-500 truncate"><%= @subtitle %></p>
    </div>
    <%= render_slot(@action) %>
  </div>
  """
end
```

---

## CategoryCard

File: `category_card.ex`

Left sidebar category card with image and post count.

```elixir
attr :name, :string, required: true
attr :image, :string, default: nil
attr :count, :integer, default: 0
attr :navigate, :string, default: nil

def category_card(assigns) do
  ~H"""
  <.link navigate={@navigate} class="flex items-center gap-3 p-3 rounded-2xl hover:bg-white hover:shadow-sm transition-all">
    <img :if={@image} src={@image} class="w-12 h-12 rounded-xl object-cover" />
    <div :if={!@image} class="w-12 h-12 rounded-xl bg-gradient-to-br from-pink-200 to-indigo-200" />
    <div>
      <p class="font-semibold text-sm text-gray-900"><%= @name %></p>
      <p class="text-xs text-gray-500"><%= @count %> posts</p>
    </div>
  </.link>
  """
end
```

---

## EmptyState

File: `empty_state.ex`

Empty state with icon, message, and optional CTA.

```elixir
attr :icon, :string, default: "hero-inbox"
attr :title, :string, required: true
attr :message, :string, default: nil
slot :action

def empty_state(assigns) do
  ~H"""
  <div class="flex flex-col items-center justify-center py-16 px-6 text-center">
    <div class="w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center mb-4">
      <.icon name={@icon} class="w-8 h-8 text-gray-400" />
    </div>
    <h3 class="text-lg font-semibold text-gray-900"><%= @title %></h3>
    <p :if={@message} class="text-sm text-gray-500 mt-1 max-w-sm"><%= @message %></p>
    <div :if={@action != []} class="mt-4">
      <%= render_slot(@action) %>
    </div>
  </div>
  """
end
```

---

## Skeleton

File: `skeleton.ex`

Loading skeleton placeholders.

```elixir
attr :type, :atom, values: [:text, :avatar, :card, :image], default: :text
attr :class, :string, default: ""

def skeleton(assigns) do
  ~H"""
  <div class={["animate-pulse", skeleton_class(@type), @class]} />
  """
end

def skeleton_card(assigns) do
  ~H"""
  <div class="bg-white rounded-3xl shadow-[0_4px_20px_rgba(0,0,0,0.05)] p-6 animate-pulse">
    <div class="flex items-center gap-3">
      <div class="w-10 h-10 bg-gray-200 rounded-full" />
      <div class="flex-1 space-y-2">
        <div class="h-4 bg-gray-200 rounded w-1/3" />
        <div class="h-3 bg-gray-200 rounded w-1/4" />
      </div>
    </div>
    <div class="mt-4 space-y-2">
      <div class="h-3 bg-gray-200 rounded w-full" />
      <div class="h-3 bg-gray-200 rounded w-4/5" />
    </div>
  </div>
  """
end

defp skeleton_class(:text), do: "h-4 bg-gray-200 rounded"
defp skeleton_class(:avatar), do: "w-10 h-10 bg-gray-200 rounded-full"
defp skeleton_class(:card), do: "h-40 bg-gray-200 rounded-3xl"
defp skeleton_class(:image), do: "h-48 bg-gray-200 rounded-2xl"
```

---

## EngagementBar

File: `engagement_bar.ex`

Like/comment/share action bar for posts and goals.

```elixir
attr :likes_count, :integer, default: 0
attr :comments_count, :integer, default: 0
attr :shares_count, :integer, default: 0
attr :is_liked, :boolean, default: false
attr :on_like, :string, default: nil
attr :on_comment, :string, default: nil

def engagement_bar(assigns) do
  ~H"""
  <div class="flex items-center justify-between mt-4 pt-3 border-t border-gray-100">
    <div class="flex items-center gap-4">
      <button
        phx-click={@on_like}
        class={["flex items-center gap-1.5 text-sm transition-colors",
          @is_liked && "text-red-500" || "text-gray-500 hover:text-red-500"]}
      >
        <.icon name={@is_liked && "hero-heart-solid" || "hero-heart"} class="w-5 h-5" />
        <span :if={@likes_count > 0}><%= @likes_count %></span>
      </button>
      <button
        phx-click={@on_comment}
        class="flex items-center gap-1.5 text-sm text-gray-500 hover:text-blue-500 transition-colors"
      >
        <.icon name="hero-chat-bubble-left" class="w-5 h-5" />
        <span :if={@comments_count > 0}><%= @comments_count %></span>
      </button>
    </div>
    <button class="flex items-center gap-1.5 text-sm text-gray-500 hover:text-gray-700 transition-colors">
      <.icon name="hero-share" class="w-5 h-5" />
    </button>
  </div>
  """
end
```

---

## ProgressBar

File: `progress_bar.ex`

Goal/challenge progress indicator.

```elixir
attr :value, :integer, default: 0
attr :max, :integer, default: 100
attr :size, :atom, values: [:sm, :md, :lg], default: :md
attr :color, :atom, values: [:blue, :green, :red, :purple], default: :blue
attr :show_label, :boolean, default: true

def progress_bar(assigns) do
  assigns = assign(assigns, :percentage, min(round(assigns.value / max(assigns.max, 1) * 100), 100))

  ~H"""
  <div class="w-full">
    <div :if={@show_label} class="flex justify-between text-xs text-gray-500 mb-1">
      <span><%= @value %>/<%= @max %></span>
      <span><%= @percentage %>%</span>
    </div>
    <div class={["w-full bg-gray-100 rounded-full overflow-hidden", bar_height(@size)]}>
      <div
        class={["rounded-full transition-all duration-500", bar_color(@color), bar_height(@size)]}
        style={"width: #{@percentage}%"}
      />
    </div>
  </div>
  """
end

defp bar_height(:sm), do: "h-1.5"
defp bar_height(:md), do: "h-2.5"
defp bar_height(:lg), do: "h-4"

defp bar_color(:blue), do: "bg-blue-500"
defp bar_color(:green), do: "bg-green-500"
defp bar_color(:red), do: "bg-red-500"
defp bar_color(:purple), do: "bg-purple-500"
```

---

## SectionHeader

File: `section_header.ex`

Section title with optional "View All" link.

```elixir
attr :title, :string, required: true
attr :link_text, :string, default: nil
attr :link_to, :string, default: nil
attr :class, :string, default: ""

def section_header(assigns) do
  ~H"""
  <div class={["flex items-center justify-between mb-4", @class]}>
    <h2 class="text-lg font-semibold text-gray-900"><%= @title %></h2>
    <.link :if={@link_text} navigate={@link_to} class="text-sm font-medium text-[#FF6B6B] hover:text-red-600">
      <%= @link_text %>
    </.link>
  </div>
  """
end
```

---

## UserMiniCard

File: `user_mini_card.ex`

Compact user card for suggestions and mentions.

```elixir
attr :name, :string, required: true
attr :username, :string, default: nil
attr :avatar, :string, default: nil
attr :navigate, :string, default: nil
slot :action

def user_mini_card(assigns) do
  ~H"""
  <div class="flex items-center gap-3 py-2">
    <.avatar name={@name} src={@avatar} size={:md} />
    <div class="flex-1 min-w-0">
      <p class="text-sm font-semibold text-gray-900 truncate"><%= @name %></p>
      <p :if={@username} class="text-xs text-gray-500 truncate">@<%= @username %></p>
    </div>
    <%= render_slot(@action) %>
  </div>
  """
end
```

---

## BottomNav

File: `bottom_nav.ex`

Mobile-only bottom navigation bar.

```elixir
attr :current_path, :string, required: true
attr :current_user, :map, default: nil

def bottom_nav(assigns) do
  ~H"""
  <nav class="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-100 lg:hidden z-50 safe-area-pb">
    <div class="flex items-center justify-around h-16">
      <.nav_item icon="hero-home" label="Home" to="/" active={@current_path == "/"} />
      <.nav_item icon="hero-magnifying-glass" label="Explore" to="/goals" active={String.starts_with?(@current_path, "/goals")} />
      <.nav_item icon="hero-plus-circle-solid" label="Create" to="/goals/new" active={@current_path == "/goals/new"} primary />
      <.nav_item icon="hero-fire" label="Challenges" to="/challenges" active={String.starts_with?(@current_path, "/challenges")} />
      <.nav_item
        :if={@current_user}
        icon="hero-user"
        label="Profile"
        to={"/u/#{@current_user.user_name}"}
        active={String.starts_with?(@current_path, "/u/")}
      />
    </div>
  </nav>
  """
end

attr :icon, :string, required: true
attr :label, :string, required: true
attr :to, :string, required: true
attr :active, :boolean, default: false
attr :primary, :boolean, default: false

defp nav_item(assigns) do
  ~H"""
  <.link navigate={@to} class={[
    "flex flex-col items-center gap-0.5 px-3 py-1",
    @primary && "text-[#FF6B6B]",
    !@primary && @active && "text-gray-900",
    !@primary && !@active && "text-gray-400"
  ]}>
    <.icon name={@icon} class={["w-6 h-6", @primary && "w-7 h-7"]} />
    <span class="text-[10px] font-medium"><%= @label %></span>
  </.link>
  """
end
```

---

## StatusBadge

File: `status_badge.ex`

Status indicator for goals, challenges, users.

```elixir
attr :status, :atom, required: true
attr :size, :atom, values: [:sm, :md], default: :sm

def status_badge(assigns) do
  ~H"""
  <span class={[
    "inline-flex items-center gap-1 font-medium rounded-full",
    status_style(@status),
    badge_size(@size)
  ]}>
    <span class={["rounded-full", dot_size(@size), dot_color(@status)]} />
    <%= status_label(@status) %>
  </span>
  """
end

defp status_style(:active), do: "bg-green-50 text-green-700"
defp status_style(:completed), do: "bg-blue-50 text-blue-700"
defp status_style(:paused), do: "bg-amber-50 text-amber-700"
defp status_style(:cancelled), do: "bg-gray-100 text-gray-600"
defp status_style(:failed), do: "bg-red-50 text-red-700"
defp status_style(_), do: "bg-gray-100 text-gray-600"

defp dot_color(:active), do: "bg-green-500"
defp dot_color(:completed), do: "bg-blue-500"
defp dot_color(:paused), do: "bg-amber-500"
defp dot_color(:cancelled), do: "bg-gray-400"
defp dot_color(:failed), do: "bg-red-500"
defp dot_color(_), do: "bg-gray-400"

defp badge_size(:sm), do: "px-2 py-0.5 text-xs"
defp badge_size(:md), do: "px-2.5 py-1 text-sm"

defp dot_size(:sm), do: "w-1.5 h-1.5"
defp dot_size(:md), do: "w-2 h-2"

defp status_label(:active), do: "Active"
defp status_label(:completed), do: "Completed"
defp status_label(:paused), do: "Paused"
defp status_label(:cancelled), do: "Cancelled"
defp status_label(:failed), do: "Failed"
defp status_label(status), do: status |> to_string() |> String.capitalize()
```

---

## ThreeColumnLayout

File: `three_column_layout.ex`

The primary page layout matching the reference designs. Mobile: single column. Desktop: 3-column grid.

```elixir
slot :left_sidebar
slot :main_content, required: true
slot :right_sidebar

def three_column_layout(assigns) do
  ~H"""
  <div class="min-h-screen bg-[#FFF5F2]">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
      <div class="lg:grid lg:grid-cols-12 lg:gap-8">
        <!-- Left Sidebar -->
        <aside :if={@left_sidebar != []} class="hidden lg:block lg:col-span-3">
          <div class="sticky top-6 space-y-6">
            <%= render_slot(@left_sidebar) %>
          </div>
        </aside>

        <!-- Main Content -->
        <main class={[
          "space-y-6",
          @left_sidebar != [] && @right_sidebar != [] && "lg:col-span-6",
          @left_sidebar != [] && @right_sidebar == [] && "lg:col-span-9",
          @left_sidebar == [] && @right_sidebar != [] && "lg:col-span-9",
          @left_sidebar == [] && @right_sidebar == [] && "lg:col-span-12"
        ]}>
          <%= render_slot(@main_content) %>
        </main>

        <!-- Right Sidebar -->
        <aside :if={@right_sidebar != []} class="hidden lg:block lg:col-span-3">
          <div class="sticky top-6 space-y-6">
            <%= render_slot(@right_sidebar) %>
          </div>
        </aside>
      </div>
    </div>
  </div>
  """
end
```
