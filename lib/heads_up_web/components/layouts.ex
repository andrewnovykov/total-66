defmodule HeadsUpWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use HeadsUpWeb, :controller` and
  `use HeadsUpWeb, :live_view`.
  """
  use HeadsUpWeb, :html

  embed_templates "layouts/*"

  # ── Shared top navigation bar ──────────────────────────────────
  # Used by ALL layouts (public, app, and layout:false pages).

  attr :current_user, :map, default: nil

  def topnav(assigns) do
    ~H"""
    <nav
      x-data="{ mobileMenuOpen: false }"
      class="fixed top-0 left-0 right-0 z-[200] h-16 px-5 sm:px-6 flex justify-between items-center backdrop-blur-[20px] bg-[rgba(10,10,10,0.85)] border-b border-[rgba(255,255,255,0.06)]"
    >
      <%!-- Left: hamburger (mobile) + logo --%>
      <div class="flex items-center gap-4">
        <button
          class="flex sm:hidden w-9 h-9 rounded-lg border border-[rgba(255,255,255,0.06)] text-t66-text-secondary items-center justify-center text-[1.2rem] cursor-pointer bg-transparent hover:bg-[rgba(255,255,255,0.05)] transition-all"
          @click="mobileMenuOpen = !mobileMenuOpen"
        >
          <span x-text="mobileMenuOpen ? '✕' : '☰'"></span>
        </button>
        <.link navigate={~p"/"} class="font-display text-[1.5rem] tracking-[4px] text-t66-text no-underline">
          TOTAL <span class="text-t66-accent">66</span>
        </.link>
      </div>

      <%!-- Center: page links (desktop) --%>
      <div class="hidden sm:flex gap-1">
        <.link
          navigate={~p"/"}
          class="text-t66-text-secondary no-underline text-[0.78rem] tracking-[1px] uppercase py-1.5 px-3 rounded-md transition-all hover:text-t66-text hover:bg-[rgba(255,255,255,0.05)]"
        >
          Home
        </.link>
        <.link
          navigate={~p"/challenges"}
          class="text-t66-text-secondary no-underline text-[0.78rem] tracking-[1px] uppercase py-1.5 px-3 rounded-md transition-all hover:text-t66-text hover:bg-[rgba(255,255,255,0.05)]"
        >
          Challenges
        </.link>
        <.link
          navigate={~p"/people"}
          class="text-t66-text-secondary no-underline text-[0.78rem] tracking-[1px] uppercase py-1.5 px-3 rounded-md transition-all hover:text-t66-text hover:bg-[rgba(255,255,255,0.05)]"
        >
          Members
        </.link>
      </div>

      <%!-- Right: Login or avatar --%>
      <div class="flex items-center gap-3">
        <%= if @current_user do %>
          <.link
            navigate={~p"/my-challenges"}
            class="flex items-center gap-2 no-underline group"
          >
            <div class="w-9 h-9 rounded-full bg-t66-card border-2 border-[rgba(255,255,255,0.06)] flex items-center justify-center font-display text-[0.85rem] tracking-[1px] text-t66-text-muted group-hover:border-t66-accent transition-colors">
              {String.first(@current_user.name || @current_user.user_name || "U") |> String.upcase()}
            </div>
          </.link>
        <% else %>
          <.link
            navigate={~p"/users/log_in"}
            class="text-t66-accent no-underline text-[0.78rem] tracking-[1px] uppercase py-1.5 px-4 rounded-lg border border-[rgba(255,77,0,0.3)] hover:bg-[rgba(255,77,0,0.15)] transition-all font-bold"
          >
            Login
          </.link>
        <% end %>
      </div>

      <%!-- Mobile dropdown menu --%>
      <div
        x-show="mobileMenuOpen"
        x-transition:enter="transition ease-out duration-200"
        x-transition:enter-start="opacity-0 -translate-y-2"
        x-transition:enter-end="opacity-100 translate-y-0"
        x-transition:leave="transition ease-in duration-150"
        x-transition:leave-start="opacity-100 translate-y-0"
        x-transition:leave-end="opacity-0 -translate-y-2"
        @click.outside="mobileMenuOpen = false"
        class="absolute top-16 left-0 right-0 bg-[rgba(10,10,10,0.97)] border-b border-[rgba(255,255,255,0.06)] p-5 flex flex-col gap-1 sm:hidden backdrop-blur-[20px]"
        style="display: none;"
      >
        <.link
          navigate={~p"/"}
          class="text-t66-text-secondary no-underline text-[0.88rem] py-3 px-4 rounded-lg uppercase tracking-[1.5px] font-medium hover:text-t66-text hover:bg-[rgba(255,255,255,0.04)] transition-all"
          @click="mobileMenuOpen = false"
        >
          Home
        </.link>
        <.link
          navigate={~p"/challenges"}
          class="text-t66-text-secondary no-underline text-[0.88rem] py-3 px-4 rounded-lg uppercase tracking-[1.5px] font-medium hover:text-t66-text hover:bg-[rgba(255,255,255,0.04)] transition-all"
          @click="mobileMenuOpen = false"
        >
          Challenges
        </.link>
        <.link
          navigate={~p"/people"}
          class="text-t66-text-secondary no-underline text-[0.88rem] py-3 px-4 rounded-lg uppercase tracking-[1.5px] font-medium hover:text-t66-text hover:bg-[rgba(255,255,255,0.04)] transition-all"
          @click="mobileMenuOpen = false"
        >
          Members
        </.link>
        <div class="h-px bg-[rgba(255,255,255,0.06)] my-2"></div>
        <%= if @current_user do %>
          <.link
            navigate={~p"/my-challenges"}
            class="text-t66-accent no-underline text-[0.88rem] py-3 px-4 rounded-lg uppercase tracking-[1.5px] font-bold hover:bg-[rgba(255,77,0,0.08)] transition-all"
            @click="mobileMenuOpen = false"
          >
            My Hub
          </.link>
        <% else %>
          <.link
            navigate={~p"/users/log_in"}
            class="text-t66-accent no-underline text-[0.88rem] py-3 px-4 rounded-lg uppercase tracking-[1.5px] font-bold hover:bg-[rgba(255,77,0,0.08)] transition-all"
            @click="mobileMenuOpen = false"
          >
            Login
          </.link>
          <.link
            navigate={~p"/users/register"}
            class="text-t66-text-secondary no-underline text-[0.88rem] py-3 px-4 rounded-lg uppercase tracking-[1.5px] font-medium hover:text-t66-text hover:bg-[rgba(255,255,255,0.04)] transition-all"
            @click="mobileMenuOpen = false"
          >
            Register
          </.link>
        <% end %>
      </div>
    </nav>
    """
  end

  # ── Sidebar link for My Hub layout ─────────────────────────────

  attr :href, :string, required: true
  attr :label, :string, required: true
  attr :icon, :string, required: true
  attr :active, :boolean, default: false
  attr :badge, :string, default: nil

  def sidebar_link(assigns) do
    ~H"""
    <a
      href={@href}
      class={[
        "relative flex items-center gap-3 px-3.5 py-[11px] rounded-[10px] text-[0.88rem] transition-all w-full",
        if(@active,
          do: "text-t66-accent bg-[rgba(255,77,0,0.08)] font-semibold",
          else: "text-t66-text-secondary hover:text-t66-text hover:bg-[rgba(255,255,255,0.04)] font-medium"
        )
      ]}
    >
      <%= if @active do %>
        <span class="absolute left-0 top-2 bottom-2 w-[3px] rounded-r-[3px] bg-t66-accent"></span>
      <% end %>
      <.icon name={@icon} class="w-5 h-5 flex-shrink-0" />
      <span>{@label}</span>
      <%= if @badge do %>
        <span class="ml-auto min-w-[20px] h-5 px-1.5 rounded-full flex items-center justify-center text-[0.65rem] font-bold bg-t66-accent text-white">
          {@badge}
        </span>
      <% end %>
    </a>
    """
  end
end
