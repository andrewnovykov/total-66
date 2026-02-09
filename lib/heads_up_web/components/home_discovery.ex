defmodule HeadsUpWeb.Components.HomeDiscovery do
  use HeadsUpWeb, :html

  attr :current_user, :map, default: nil
  attr :trending_count, :integer, required: true
  attr :groups_count, :integer, required: true
  attr :spotlight_count, :integer, required: true

  def hero(assigns) do
    ~H"""
    <section class="relative overflow-hidden rounded-[24px] border border-[#E5E7EB] bg-[linear-gradient(125deg,#0B1D3A_0%,#0D2F4F_48%,#0B7A8C_100%)] p-6 text-white shadow-[0_4px_20px_rgba(0,0,0,0.05)] sm:p-8">
      <div class="pointer-events-none absolute -left-12 -top-8 h-52 w-52 rounded-full bg-[radial-gradient(circle,rgba(59,130,246,0.28)_0%,rgba(59,130,246,0)_70%)] blur-2xl">
      </div>
      <div class="pointer-events-none absolute -right-16 -bottom-12 h-64 w-64 rounded-full bg-[radial-gradient(circle,rgba(16,185,129,0.25)_0%,rgba(16,185,129,0)_72%)] blur-2xl">
      </div>

      <div class="relative grid gap-6 lg:grid-cols-[1.1fr_0.9fr] lg:items-center">
        <div class="space-y-4">
          <span class="inline-flex rounded-full border border-white/35 bg-white/10 px-4 py-1.5 text-[12px] font-medium uppercase tracking-[0.14em]">
            Daily Discovery
          </span>
          <h1 class="max-w-[20ch] text-[28px] font-bold leading-[1.15]">
            Set fewer goals. Finish more.
          </h1>
          <p class="max-w-[58ch] text-[14px] font-normal leading-[1.5] text-slate-100">
            Discover high-momentum goals, active communities, and disciplined people who can raise your execution level this week.
          </p>

          <div class="flex flex-wrap gap-3 pt-1">
            <%= if @current_user do %>
              <.link
                navigate={~p"/goals/new"}
                class="inline-flex items-center rounded-xl bg-[#111827] px-5 py-2.5 text-[14px] font-semibold text-white transition hover:-translate-y-0.5 hover:shadow-[0_10px_25px_rgba(0,0,0,0.08)]"
              >
                Create your next goal
              </.link>
            <% else %>
              <.link
                navigate={~p"/users/register"}
                class="inline-flex items-center rounded-xl bg-[#111827] px-5 py-2.5 text-[14px] font-semibold text-white transition hover:-translate-y-0.5 hover:shadow-[0_10px_25px_rgba(0,0,0,0.08)]"
              >
                Get started
              </.link>
            <% end %>
            <.link
              navigate={~p"/all-goals"}
              class="inline-flex items-center rounded-xl border border-white/40 bg-white/10 px-5 py-2.5 text-[14px] font-semibold text-white transition hover:bg-white/20"
            >
              Explore all goals
            </.link>
            <.link
              navigate={~p"/challenges"}
              class="inline-flex items-center rounded-xl border border-white/35 bg-transparent px-5 py-2.5 text-[14px] font-semibold text-white transition hover:bg-white/10"
            >
              Browse challenges
            </.link>
          </div>
        </div>

        <div class="grid gap-3">
          <.metric_tile
            title="Trending Goals"
            value={@trending_count}
            subtitle="Top momentum picks for today."
          />
          <.metric_tile
            title="Popular Groups"
            value={@groups_count}
            subtitle="Communities with active goal creation."
          />
          <.metric_tile
            title="Spotlight Users"
            value={@spotlight_count}
            subtitle="Members demonstrating consistency."
          />
        </div>
      </div>
    </section>
    """
  end

  attr :eyebrow, :string, required: true
  attr :title, :string, required: true
  attr :cta_label, :string, required: true
  attr :cta_path, :string, required: true

  def section_header(assigns) do
    ~H"""
    <div class="flex flex-wrap items-end justify-between gap-3">
      <div class="space-y-1">
        <p class="text-[12px] font-semibold uppercase tracking-[0.14em] text-[#0B7A8C]">{@eyebrow}</p>
        <h2 class="text-[20px] font-semibold leading-[1.2] text-[#111827]">{@title}</h2>
      </div>
      <.link
        navigate={@cta_path}
        class="inline-flex items-center rounded-full border border-[#E5E7EB] bg-white px-4 py-2 text-[14px] font-semibold text-[#3B82F6] transition hover:bg-[#F3F7FF]"
      >
        {@cta_label}
      </.link>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :description, :string, required: true

  def empty_state(assigns) do
    ~H"""
    <div class="rounded-[24px] border border-dashed border-[#E5E7EB] bg-white px-6 py-12 text-center shadow-[0_4px_20px_rgba(0,0,0,0.05)]">
      <p class="text-[16px] font-semibold text-[#111827]">{@title}</p>
      <p class="pt-2 text-[14px] leading-[1.5] text-[#6B7280]">{@description}</p>
    </div>
    """
  end

  attr :goal, :map, required: true
  attr :fallback_image, :string, required: true

  def goal_card(assigns) do
    progress = assigns.goal.progress || 0
    progress = progress |> max(0) |> min(100)

    status =
      assigns.goal.status
      |> to_string()
      |> String.replace("_", " ")
      |> String.capitalize()

    assigns = assign(assigns, progress: progress, status: status)

    ~H"""
    <.link
      navigate={~p"/goals/#{@goal.id}"}
      class="group overflow-hidden rounded-[24px] border border-[#E5E7EB] bg-white shadow-[0_4px_20px_rgba(0,0,0,0.05)] transition hover:-translate-y-0.5 hover:shadow-[0_10px_25px_rgba(0,0,0,0.08)]"
    >
      <div
        class="relative aspect-[16/10] bg-cover bg-center bg-no-repeat"
        style={"background-image: url('#{@goal.image_path || @fallback_image}');"}
      >
        <div class="absolute inset-0 bg-gradient-to-t from-black/85 via-black/30 to-transparent">
        </div>
        <div class="absolute left-4 top-4 flex items-center gap-2">
          <span class="rounded-full bg-[#DBEAFE] px-3 py-1 text-[12px] font-semibold uppercase tracking-[0.08em] text-[#1E40AF]">
            Trending
          </span>
          <span class="rounded-full bg-white/95 px-3 py-1 text-[12px] font-medium uppercase tracking-[0.08em] text-[#111827]">
            {@goal.group.name}
          </span>
        </div>
        <div class="absolute inset-x-4 bottom-4">
          <h3 class="text-[16px] font-semibold leading-[1.25] text-white">
            {@goal.title}
          </h3>
          <p class="pt-1 text-[14px] text-slate-200">
            By {@goal.user.name || @goal.user.user_name || "Anonymous"}
          </p>
        </div>
      </div>

      <div class="space-y-3 p-4">
        <div class="flex items-center justify-between gap-3">
          <span class="rounded-full bg-[#DBEAFE] px-3 py-1 text-[12px] font-medium text-[#1E40AF]">
            {@status}
          </span>
          <span class="text-[14px] font-medium text-[#6B7280]">{@progress}% complete</span>
        </div>
        <div class="h-2 rounded-full bg-[#E5E7EB]">
          <div class="h-2 rounded-full bg-[#3B82F6]" style={"width: #{@progress}%"}></div>
        </div>
      </div>
    </.link>
    """
  end

  attr :group, :map, required: true
  attr :fallback_image, :string, required: true

  def group_card(assigns) do
    ~H"""
    <.link
      navigate={~p"/goals-category/#{@group.id}"}
      class="group overflow-hidden rounded-[24px] border border-[#E5E7EB] bg-white shadow-[0_4px_20px_rgba(0,0,0,0.05)] transition hover:-translate-y-0.5 hover:shadow-[0_10px_25px_rgba(0,0,0,0.08)]"
    >
      <div
        class="relative aspect-[16/10] bg-cover bg-center bg-no-repeat"
        style={"background-image: url('#{@group.image_path || @fallback_image}');"}
      >
        <div class="absolute inset-0 bg-gradient-to-t from-black/72 via-black/20 to-transparent">
        </div>
        <div class="absolute inset-x-4 bottom-4">
          <h3 class="text-[16px] font-semibold text-white">{@group.name}</h3>
        </div>
      </div>

      <div class="space-y-1 p-4">
        <p class="text-[14px] text-[#6B7280]">
          {@group.goal_count} {if @group.goal_count == 1, do: "goal", else: "goals"} tracked
        </p>
        <p class="text-[14px] font-semibold text-[#3B82F6]">Open group</p>
      </div>
    </.link>
    """
  end

  attr :user, :map, required: true
  attr :fallback_image, :string, required: true

  def spotlight_card(assigns) do
    ~H"""
    <.link
      navigate={~p"/people/#{@user.user_name || @user.id}"}
      class="rounded-[24px] border border-[#E5E7EB] bg-white p-5 shadow-[0_4px_20px_rgba(0,0,0,0.05)] transition hover:-translate-y-0.5 hover:shadow-[0_10px_25px_rgba(0,0,0,0.08)]"
    >
      <div class="flex items-center gap-4">
        <div class="relative">
          <div
            class="h-14 w-14 rounded-full bg-cover bg-center bg-no-repeat ring-2 ring-[#DBEAFE]"
            style={"background-image: url('#{@user.image_path || @fallback_image}');"}
          >
          </div>
          <span class="absolute -bottom-1 -right-1 rounded-full bg-[#1E40AF] px-2 py-0.5 text-[12px] font-medium text-white">
            Lv {@user.level}
          </span>
        </div>
        <div class="min-w-0">
          <h3 class="truncate text-[16px] font-semibold text-[#111827]">
            {@user.name || @user.user_name || "Anonymous"}
          </h3>
          <p class="truncate text-[14px] text-[#6B7280]">
            {if @user.user_name, do: "@#{@user.user_name}", else: "GoalHub member"}
          </p>
        </div>
      </div>

      <p class="pt-4 text-[14px] leading-[1.5] text-[#6B7280]">
        <%= if @user.latest_achievement do %>
          Latest achievement:
          <span class="font-medium text-[#111827]">{@user.latest_achievement}</span>
        <% else %>
          Active this week with meaningful progress updates.
        <% end %>
      </p>

      <p class="pt-3 text-[14px] font-semibold text-[#3B82F6]">View profile</p>
    </.link>
    """
  end

  attr :title, :string, required: true
  attr :value, :integer, required: true
  attr :subtitle, :string, required: true

  defp metric_tile(assigns) do
    ~H"""
    <div class="rounded-[16px] border border-white/25 bg-white/10 px-4 py-3 backdrop-blur-sm">
      <p class="text-[12px] font-medium uppercase tracking-[0.12em] text-slate-200">{@title}</p>
      <p class="pt-1 text-[32px] font-bold leading-none text-white">{@value}</p>
      <p class="pt-1 text-[14px] leading-[1.5] text-slate-100">{@subtitle}</p>
    </div>
    """
  end
end
