defmodule HeadsUpWeb.GoalCategoryLive.Index do
  use HeadsUpWeb, :live_view
  alias HeadsUp.{Groups, Goals}
  import HeadsUpWeb.Helpers.RoleHelper

  def mount(_params, _session, socket) do
    groups = Groups.list_published_groups()
    groups_with_counts = add_goal_counts(groups)

    socket =
      socket
      |> assign(:groups, groups_with_counts)
      |> assign(:filtered_groups, groups_with_counts)
      |> assign(:search_query, "")

    {:ok, socket}
  end

  def handle_event("select_group", %{"group-id" => group_id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/goals-category/#{group_id}")}
  end

  def handle_event("search", %{"query" => query}, socket) do
    filtered_groups = filter_groups(socket.assigns.groups, query)

    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:filtered_groups, filtered_groups)}
  end

  defp filter_groups(groups, ""), do: groups

  defp filter_groups(groups, query) do
    search_term = String.downcase(query)

    Enum.filter(groups, fn group ->
      String.contains?(String.downcase(group.name), search_term) ||
        String.contains?(String.downcase(group.description || ""), search_term)
    end)
  end

  defp add_goal_counts(groups) do
    group_ids = Enum.map(groups, & &1.id)
    counts_map = Goals.get_group_goal_counts(group_ids)

    Enum.map(groups, fn group ->
      counts = Map.get(counts_map, group.id, %{total_goal_amount: 0, active_goal_amount: 0})
      Map.merge(group, counts)
    end)
  end

  def render(assigns) do
    ~H"""
    <div class="flex gap-0 h-full">
      <%!-- ===== CENTER CONTENT ===== --%>
      <div class="flex-grow p-5 sm:p-8 lg:p-10 overflow-y-auto custom-scrollbar">
        <%!-- Hero Banner with Search --%>
        <div class="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-[40px] p-8 sm:p-10 lg:p-12 mb-10 relative overflow-hidden text-white soft-shadow">
          <div class="relative z-10 max-w-2xl">
            <span class="bg-blue-500/50 text-blue-100 text-xs font-bold px-4 py-1.5 rounded-full mb-5 inline-block uppercase tracking-wider">
              Browse
            </span>
            <h1 class="text-3xl sm:text-4xl lg:text-5xl font-extrabold mb-4 leading-tight">
              Goal Categories
            </h1>
            <p class="text-blue-100 mb-8 text-lg leading-relaxed">
              Explore categories and discover goals organized by theme.
            </p>

            <%!-- Search Bar --%>
            <form phx-change="search" class="relative">
              <div class="flex items-center bg-white/20 backdrop-blur-sm rounded-2xl border border-white/30 overflow-hidden focus-within:bg-white/30 transition-colors">
                <div class="pl-5 text-blue-200">
                  <.icon name="hero-magnifying-glass" class="w-5 h-5" />
                </div>
                <input
                  name="query"
                  type="text"
                  value={@search_query}
                  placeholder="Search categories..."
                  phx-debounce="300"
                  class="w-full bg-transparent text-white placeholder-blue-200 px-4 py-4 border-none focus:ring-0 text-base font-medium"
                />
                <%= if @search_query != "" do %>
                  <button
                    type="button"
                    phx-click="search"
                    phx-value-query=""
                    class="pr-5 text-blue-200 hover:text-white transition-colors"
                  >
                    <.icon name="hero-x-mark" class="w-5 h-5" />
                  </button>
                <% end %>
              </div>
            </form>
          </div>
          <div class="absolute right-0 top-0 h-full w-1/3 opacity-20 pointer-events-none flex items-center justify-center">
            <.icon name="hero-squares-2x2" class="w-48 h-48 lg:w-64 lg:h-64" />
          </div>
        </div>

        <%!-- Results Header --%>
        <div class="flex items-center justify-between mb-8">
          <div>
            <h2 class="text-2xl font-extrabold text-slate-900">
              <%= if @search_query != "" do %>
                Results for "{@search_query}"
              <% else %>
                All Categories
              <% end %>
            </h2>
            <p class="text-slate-400 text-sm font-medium mt-1">
              {length(@filtered_groups)} {if length(@filtered_groups) == 1,
                do: "category",
                else: "categories"}
            </p>
          </div>
          <%= if is_admin?(@current_user) do %>
            <.link
              navigate={~p"/admin/categories"}
              class="inline-flex items-center gap-2 bg-gradient-to-r from-blue-500 to-indigo-600 text-white text-sm font-bold px-6 py-3 rounded-xl transition-colors shadow-lg shadow-blue-500/20"
            >
              <.icon name="hero-plus" class="w-4 h-4" /> Manage Categories
            </.link>
          <% end %>
        </div>

        <%!-- Categories Grid --%>
        <%= if Enum.empty?(@filtered_groups) do %>
          <HeadsUpWeb.Components.UI.EmptyState.empty_state
            icon="hero-squares-2x2"
            title={
              if @search_query != "", do: "No categories match your search", else: "No categories yet"
            }
            message={
              if @search_query != "",
                do: "Try adjusting your search terms.",
                else: "Categories will appear here once an admin creates them."
            }
          >
            <:action>
              <%= if @search_query != "" do %>
                <button
                  phx-click="search"
                  phx-value-query=""
                  class="inline-flex items-center gap-2 bg-gradient-to-r from-blue-500 to-indigo-600 text-white text-sm font-bold px-6 py-3 rounded-xl transition-colors shadow-lg shadow-blue-500/20"
                >
                  Clear Search
                </button>
              <% end %>
            </:action>
          </HeadsUpWeb.Components.UI.EmptyState.empty_state>
        <% else %>
          <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-6">
            <%= for group <- @filtered_groups do %>
              <div phx-click="select_group" phx-value-group-id={group.id} class="cursor-pointer">
                <HeadsUpWeb.Components.UI.Card.card hover>
                  <%!-- Category Image --%>
                  <div class="-mx-8 -mt-8 mb-6">
                    <%= if group.image_path do %>
                      <img
                        src={group.image_path}
                        alt={group.name}
                        class="w-full h-48 object-cover rounded-t-[40px]"
                      />
                    <% else %>
                      <div class="w-full h-48 bg-gradient-to-br from-blue-400 to-indigo-500 rounded-t-[40px] flex items-center justify-center">
                        <div class="w-20 h-20 bg-white/20 backdrop-blur-sm rounded-full flex items-center justify-center">
                          <span class="text-3xl font-extrabold text-white">
                            {String.first(group.name) |> String.upcase()}
                          </span>
                        </div>
                      </div>
                    <% end %>
                  </div>

                  <%!-- Category Content --%>
                  <h3 class="text-xl font-extrabold text-slate-900 mb-2">{group.name}</h3>
                  <%= if group.description do %>
                    <p class="text-slate-500 text-base mb-6 leading-relaxed line-clamp-2">
                      {group.description}
                    </p>
                  <% end %>

                  <%!-- Stats Row --%>
                  <div class="flex items-center gap-4">
                    <div class="flex items-center gap-2 bg-blue-50 px-4 py-2 rounded-full">
                      <.icon name="hero-flag" class="w-4 h-4 text-blue-600" />
                      <span class="text-blue-600 font-bold text-sm">
                        {group.total_goal_amount} goals
                      </span>
                    </div>
                    <div class="flex items-center gap-2 bg-green-50 px-4 py-2 rounded-full">
                      <.icon name="hero-check-circle" class="w-4 h-4 text-green-600" />
                      <span class="text-green-600 font-bold text-sm">
                        {group.active_goal_amount} active
                      </span>
                    </div>
                  </div>
                </HeadsUpWeb.Components.UI.Card.card>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>

      <%!-- ===== RIGHT SIDEBAR (Desktop only) ===== --%>
      <aside class="hidden xl:flex w-[420px] flex-shrink-0 border-l border-slate-100 p-8 flex-col gap-10 overflow-y-auto custom-scrollbar bg-white">
        <%!-- Quick Stats --%>
        <section>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Overview</h3>
          <div class="space-y-4">
            <div class="flex items-center gap-4 p-5 bg-slate-50 rounded-2xl">
              <div class="w-14 h-14 bg-blue-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-squares-2x2" class="w-7 h-7 text-blue-600" />
              </div>
              <div>
                <p class="text-3xl font-extrabold text-slate-900">{length(@groups)}</p>
                <p class="text-xs text-slate-400 font-medium">Total Categories</p>
              </div>
            </div>
            <div class="flex items-center gap-4 p-5 bg-slate-50 rounded-2xl">
              <div class="w-14 h-14 bg-indigo-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-flag" class="w-7 h-7 text-indigo-500" />
              </div>
              <div>
                <p class="text-3xl font-extrabold text-slate-900">
                  {Enum.reduce(@groups, 0, fn g, acc -> acc + g.total_goal_amount end)}
                </p>
                <p class="text-xs text-slate-400 font-medium">Total Goals</p>
              </div>
            </div>
            <div class="flex items-center gap-4 p-5 bg-slate-50 rounded-2xl">
              <div class="w-14 h-14 bg-green-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-check-circle" class="w-7 h-7 text-green-500" />
              </div>
              <div>
                <p class="text-3xl font-extrabold text-slate-900">
                  {Enum.reduce(@groups, 0, fn g, acc -> acc + g.active_goal_amount end)}
                </p>
                <p class="text-xs text-slate-400 font-medium">Active Goals</p>
              </div>
            </div>
          </div>
        </section>

        <%!-- Top Categories --%>
        <section>
          <HeadsUpWeb.Components.UI.SectionHeader.section_header title="Most Active" />
          <div class="space-y-4">
            <%= for group <- @groups |> Enum.sort_by(& &1.active_goal_amount, :desc) |> Enum.take(5) do %>
              <div
                phx-click="select_group"
                phx-value-group-id={group.id}
                class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl cursor-pointer hover:bg-slate-100 transition-colors"
              >
                <%= if group.image_path do %>
                  <img
                    src={group.image_path}
                    alt={group.name}
                    class="w-12 h-12 rounded-xl object-cover"
                  />
                <% else %>
                  <div class="w-12 h-12 rounded-xl bg-gradient-to-br from-blue-400 to-indigo-500 flex items-center justify-center">
                    <span class="text-sm font-bold text-white">
                      {String.first(group.name) |> String.upcase()}
                    </span>
                  </div>
                <% end %>
                <div class="flex-1 min-w-0">
                  <h5 class="font-bold text-slate-900 text-sm truncate">{group.name}</h5>
                  <p class="text-slate-400 text-xs">{group.active_goal_amount} active goals</p>
                </div>
                <.icon name="hero-chevron-right" class="w-4 h-4 text-slate-400" />
              </div>
            <% end %>
          </div>
        </section>

        <%!-- Create Goal Promo --%>
        <%= if @current_user do %>
          <div class="bg-gradient-to-br from-blue-600 to-indigo-700 p-6 rounded-3xl relative overflow-hidden shadow-lg shadow-blue-500/20">
            <div class="relative z-10">
              <p class="text-white font-bold leading-tight mb-2">Create a Goal</p>
              <p class="text-blue-200 text-xs mb-4">Pick a category & start tracking</p>
              <.link
                navigate={~p"/goals/new"}
                class="inline-block bg-white text-blue-600 text-xs font-bold px-5 py-2.5 rounded-xl hover:bg-blue-50 transition-colors"
              >
                New Goal
              </.link>
            </div>
            <div class="absolute -right-4 -bottom-4 opacity-20 text-white">
              <.icon name="hero-rocket-launch" class="w-16 h-16" />
            </div>
          </div>
        <% end %>
      </aside>
    </div>
    """
  end
end
