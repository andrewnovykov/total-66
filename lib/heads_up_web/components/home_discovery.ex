defmodule HeadsUpWeb.Components.HomeDiscovery do
  use HeadsUpWeb, :html

  attr :current_user, :map, default: nil
  attr :spotlight_count, :integer, required: true
  attr :challenge_categories_count, :integer, required: true

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
            Transform in 66 days.
          </h1>
          <p class="max-w-[58ch] text-[14px] font-normal leading-[1.5] text-slate-100">
            Build lasting habits with structured challenges, daily accountability, and real progress tracking.
          </p>

          <div class="flex flex-wrap gap-3 pt-1">
            <%= if @current_user do %>
              <.link
                navigate={~p"/challenges/new"}
                class="inline-flex items-center rounded-xl bg-[#111827] px-5 py-2.5 text-[14px] font-semibold text-white transition hover:-translate-y-0.5 hover:shadow-[0_10px_25px_rgba(0,0,0,0.08)]"
              >
                Start a challenge
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
              navigate={~p"/challenges"}
              class="inline-flex items-center rounded-xl border border-white/40 bg-white/10 px-5 py-2.5 text-[14px] font-semibold text-white transition hover:bg-white/20"
            >
              Browse challenges
            </.link>
          </div>
        </div>

        <div class="grid gap-3">
          <.metric_tile
            title="Challenge Categories"
            value={@challenge_categories_count}
            subtitle="Explore structured challenge templates."
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
            {if @user.user_name, do: "@#{@user.user_name}", else: "Total 66 member"}
          </p>
        </div>
      </div>

      <p class="pt-4 text-[14px] leading-[1.5] text-[#6B7280]">
        Active this week with meaningful progress updates.
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
