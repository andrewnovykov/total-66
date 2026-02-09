defmodule HeadsUpWeb.AllGoalsLive.Index do
  use HeadsUpWeb, :live_view
  alias HeadsUp.{Goals, Accounts}
  alias HeadsUp.Repo
  import Ecto.Query

  def mount(_params, _session, socket) do
    current_user = socket.assigns[:current_user]
    current_user_id = if current_user, do: current_user.id, else: nil

    all_goals =
      Goals.list_goals()
      |> Repo.preload([:group, :user, :goal_likes, :goal_subscriptions, :goal_posts])
      |> Goals.add_social_counts()

    categories = get_categories()

    socket =
      socket
      |> assign(:all_goals, all_goals)
      |> assign(:filtered_goals, all_goals)
      |> assign(:search_query, "")
      |> assign(:current_user_id, current_user_id)
      |> assign(:current_user, current_user)
      |> assign(:active_filter, "all")
      |> assign(:active_category, nil)
      |> assign(:categories, categories)

    {:ok, socket}
  end

  def handle_event("search", %{"query" => query}, socket) do
    filtered =
      apply_filters(
        socket.assigns.all_goals,
        query,
        socket.assigns.active_filter,
        socket.assigns.active_category
      )

    {:noreply,
     socket
     |> assign(:filtered_goals, filtered)
     |> assign(:search_query, query)}
  end

  def handle_event("filter", %{"filter" => filter}, socket) do
    filtered =
      apply_filters(
        socket.assigns.all_goals,
        socket.assigns.search_query,
        filter,
        socket.assigns.active_category
      )

    {:noreply,
     socket
     |> assign(:filtered_goals, filtered)
     |> assign(:active_filter, filter)}
  end

  def handle_event("filter_category", %{"category-id" => "0"}, socket) do
    filtered =
      apply_filters(
        socket.assigns.all_goals,
        socket.assigns.search_query,
        socket.assigns.active_filter,
        nil
      )

    {:noreply,
     socket
     |> assign(:filtered_goals, filtered)
     |> assign(:active_category, nil)}
  end

  def handle_event("filter_category", %{"category-id" => category_id}, socket) do
    {cat_id, _} = Integer.parse(category_id)
    active = if socket.assigns.active_category == cat_id, do: nil, else: cat_id

    filtered =
      apply_filters(
        socket.assigns.all_goals,
        socket.assigns.search_query,
        socket.assigns.active_filter,
        active
      )

    {:noreply,
     socket
     |> assign(:filtered_goals, filtered)
     |> assign(:active_category, active)}
  end

  defp apply_filters(goals, query, filter, category_id) do
    goals
    |> filter_by_search(query)
    |> filter_by_status(filter)
    |> filter_by_category(category_id)
  end

  defp filter_by_search(goals, ""), do: goals

  defp filter_by_search(goals, query) do
    q = String.downcase(query)

    Enum.filter(goals, fn goal ->
      String.contains?(String.downcase(goal.title), q) ||
        (goal.description && String.contains?(String.downcase(goal.description), q)) ||
        (goal.group && String.contains?(String.downcase(goal.group.name), q)) ||
        (goal.user && goal.user.name && String.contains?(String.downcase(goal.user.name), q))
    end)
  end

  defp filter_by_status(goals, "active"), do: Enum.filter(goals, &(&1.status == :active))
  defp filter_by_status(goals, "completed"), do: Enum.filter(goals, &(&1.status == :completed))
  defp filter_by_status(goals, "paused"), do: Enum.filter(goals, &(&1.status == :paused))
  defp filter_by_status(goals, _), do: goals

  defp filter_by_category(goals, nil), do: goals

  defp filter_by_category(goals, category_id) do
    Enum.filter(goals, fn goal ->
      goal.group && goal.group.id == category_id
    end)
  end

  defp get_categories do
    from(g in HeadsUp.Group,
      where: g.status == :published,
      order_by: [asc: g.name],
      limit: 20
    )
    |> Repo.all()
  end

  defp privacy_icon(:public), do: "hero-globe-alt"
  defp privacy_icon(:friends), do: "hero-user-group"
  defp privacy_icon(:friends_only), do: "hero-user-group"
  defp privacy_icon(_), do: "hero-lock-closed"

  defp privacy_label(:public), do: "Public"
  defp privacy_label(:friends), do: "Friends"
  defp privacy_label(:friends_only), do: "Friends"
  defp privacy_label(_), do: "Private"

  defp can_view_goal?(goal, current_user_id) do
    case goal.privacy do
      :public ->
        true

      :private ->
        current_user_id && current_user_id == goal.user_id

      :friends_only ->
        current_user_id &&
          (current_user_id == goal.user_id ||
             Accounts.are_friends?(current_user_id, goal.user_id))

      _ ->
        true
    end
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
              Explore
            </span>
            <h1 class="text-3xl sm:text-4xl lg:text-5xl font-extrabold mb-4 leading-tight">
              Discover Goals
            </h1>
            <p class="text-blue-100 mb-8 text-lg leading-relaxed">
              Browse goals from the community. Get inspired, follow progress, and find your next challenge.
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
                  placeholder="Search goals, categories, or people..."
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
            <.icon name="hero-flag" class="w-48 h-48 lg:w-64 lg:h-64" />
          </div>
        </div>

        <%!-- Category Pills --%>
        <%= if @categories != [] do %>
          <section class="mb-10">
            <HeadsUpWeb.Components.UI.SectionHeader.section_header
              title="Categories"
              link_text="View All"
              link_to={~p"/goals-category"}
            />
            <div class="flex gap-3 overflow-x-auto pb-4 custom-scrollbar">
              <button
                phx-click="filter_category"
                phx-value-category-id="0"
                class={[
                  "flex items-center gap-3 px-5 py-3 rounded-2xl border min-w-fit font-bold text-sm transition-all",
                  (!@active_category && "bg-slate-900 text-white border-slate-900") ||
                    "bg-white text-slate-500 border-slate-100 soft-shadow hover:border-blue-200"
                ]}
              >
                All
              </button>
              <%= for category <- @categories do %>
                <button
                  phx-click="filter_category"
                  phx-value-category-id={category.id}
                  class={[
                    "flex items-center gap-3 px-5 py-3 rounded-2xl border min-w-fit font-bold text-sm transition-all",
                    (@active_category == category.id && "bg-slate-900 text-white border-slate-900") ||
                      "bg-white text-slate-500 border-slate-100 soft-shadow hover:border-blue-200"
                  ]}
                >
                  {category.name}
                </button>
              <% end %>
            </div>
          </section>
        <% end %>

        <%!-- Filter + Results Header --%>
        <section>
          <div class="flex items-center justify-between mb-8">
            <div>
              <h2 class="text-2xl font-extrabold text-slate-900">
                <%= if @search_query != "" do %>
                  Results for "{@search_query}"
                <% else %>
                  All Goals
                <% end %>
              </h2>
              <p class="text-slate-400 text-sm font-medium mt-1">
                {length(@filtered_goals)} {if length(@filtered_goals) == 1, do: "goal", else: "goals"} found
              </p>
            </div>
            <div class="flex gap-3">
              <button
                phx-click="filter"
                phx-value-filter="all"
                class={[
                  "px-6 py-2.5 rounded-xl text-sm font-bold transition-all",
                  (@active_filter == "all" && "bg-slate-900 text-white") ||
                    "bg-white text-slate-500 soft-shadow"
                ]}
              >
                All
              </button>
              <button
                phx-click="filter"
                phx-value-filter="active"
                class={[
                  "px-6 py-2.5 rounded-xl text-sm font-bold transition-all",
                  (@active_filter == "active" && "bg-slate-900 text-white") ||
                    "bg-white text-slate-500 soft-shadow"
                ]}
              >
                Active
              </button>
              <button
                phx-click="filter"
                phx-value-filter="completed"
                class={[
                  "px-6 py-2.5 rounded-xl text-sm font-bold transition-all hidden sm:block",
                  (@active_filter == "completed" && "bg-slate-900 text-white") ||
                    "bg-white text-slate-500 soft-shadow"
                ]}
              >
                Completed
              </button>
            </div>
          </div>

          <%!-- Goals Feed --%>
          <%= if Enum.empty?(@filtered_goals) do %>
            <HeadsUpWeb.Components.UI.EmptyState.empty_state
              icon="hero-flag"
              title={if @search_query != "", do: "No goals match your search", else: "No goals yet"}
              message={
                if @search_query != "",
                  do: "Try adjusting your search terms or browse all goals.",
                  else: "Be the first to create a goal and start building momentum."
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
                <% else %>
                  <.link
                    navigate={~p"/goals/new"}
                    class="inline-flex items-center gap-2 bg-gradient-to-r from-blue-500 to-indigo-600 text-white text-sm font-bold px-6 py-3 rounded-xl transition-colors shadow-lg shadow-blue-500/20"
                  >
                    Create Goal
                  </.link>
                <% end %>
              </:action>
            </HeadsUpWeb.Components.UI.EmptyState.empty_state>
          <% else %>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
              <%= for goal <- @filtered_goals do %>
                <% viewable = can_view_goal?(goal, @current_user_id) %>
                <%= if viewable do %>
                  <.link navigate={~p"/goals/#{goal.id}"} class="block">
                    <HeadsUpWeb.Components.UI.Card.card hover>
                      <%!-- Post Header --%>
                      <div class="flex items-start justify-between mb-4">
                        <div class="flex gap-3">
                          <HeadsUpWeb.Components.UI.Avatar.avatar
                            name={goal.user.name || goal.user.user_name || "Anonymous"}
                            src={goal.user.image_path}
                            size={:md}
                          />
                          <div>
                            <h4 class="font-extrabold text-slate-900 text-sm">
                              {goal.user.name || goal.user.user_name || "Anonymous"}
                            </h4>
                            <p class="text-slate-400 text-xs font-medium">
                              {if goal.group, do: goal.group.name, else: "Uncategorized"}
                            </p>
                          </div>
                        </div>
                        <div class="flex items-center gap-1.5">
                          <HeadsUpWeb.Components.UI.StatusBadge.status_badge
                            status={goal.status}
                            size={:sm}
                          />
                          <span class="bg-slate-100 text-slate-600 text-[10px] font-bold px-2 py-1 rounded-full inline-flex items-center gap-1">
                            <.icon name={privacy_icon(goal.privacy)} class="w-3 h-3" />
                            {privacy_label(goal.privacy)}
                          </span>
                        </div>
                      </div>

                      <%!-- Goal Content --%>
                      <h3 class="text-base font-extrabold text-slate-900 mb-2 line-clamp-1">
                        {goal.title}
                      </h3>
                      <%= if goal.description do %>
                        <p class="text-slate-600 text-sm mb-4 leading-relaxed line-clamp-2">
                          {goal.description}
                        </p>
                      <% end %>

                      <%!-- Goal Image --%>
                      <%= if goal.image_path do %>
                        <img
                          src={goal.image_path}
                          alt={goal.title}
                          class="w-full h-40 object-cover rounded-2xl mb-4"
                        />
                      <% end %>

                      <%!-- Progress Bar --%>
                      <div class="mb-4">
                        <HeadsUpWeb.Components.UI.ProgressBar.progress_bar
                          value={goal.progress || 0}
                          max={100}
                          size={:sm}
                          color={:indigo}
                          show_label={true}
                        />
                      </div>

                      <%!-- Engagement Row --%>
                      <div class="flex items-center gap-4 text-xs">
                        <span class="flex items-center gap-1.5 text-pink-500 font-bold">
                          <.icon name="hero-heart-solid" class="w-4 h-4" /> {Map.get(
                            goal,
                            :like_count,
                            0
                          )} likes
                        </span>
                        <span class="flex items-center gap-1.5 text-blue-500 font-bold">
                          <.icon name="hero-eye" class="w-4 h-4" /> {Map.get(
                            goal,
                            :subscriber_count,
                            0
                          )} subscribers
                        </span>
                        <span class="flex items-center gap-1.5 text-slate-500 font-bold">
                          <.icon name="hero-chat-bubble-left" class="w-4 h-4" /> {Map.get(
                            goal,
                            :post_count,
                            0
                          )} posts
                        </span>
                      </div>
                    </HeadsUpWeb.Components.UI.Card.card>
                  </.link>
                <% else %>
                  <%!-- Restricted Goal Card --%>
                  <HeadsUpWeb.Components.UI.Card.card>
                    <div class="flex items-center gap-3">
                      <div class="w-10 h-10 rounded-full bg-slate-100 flex items-center justify-center">
                        <.icon name="hero-lock-closed" class="w-5 h-5 text-slate-400" />
                      </div>
                      <div class="flex-1 min-w-0">
                        <h4 class="font-extrabold text-slate-900 text-sm">
                          {if goal.privacy == :private, do: "Private Goal", else: "Friends Only"}
                        </h4>
                        <p class="text-slate-400 text-xs font-medium">
                          This goal's details are private
                        </p>
                      </div>
                      <span class="bg-slate-100 text-slate-600 text-xs font-bold px-2 py-1 rounded-full inline-flex items-center gap-1">
                        <.icon name={privacy_icon(goal.privacy)} class="w-3 h-3" />
                        {privacy_label(goal.privacy)}
                      </span>
                    </div>
                  </HeadsUpWeb.Components.UI.Card.card>
                <% end %>
              <% end %>
            </div>
          <% end %>
        </section>
      </div>

      <%!-- ===== RIGHT SIDEBAR (Desktop only) ===== --%>
      <aside class="hidden xl:flex w-[420px] flex-shrink-0 border-l border-slate-100 p-8 flex-col gap-10 overflow-y-auto custom-scrollbar bg-white">
        <%!-- Quick Stats --%>
        <section>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Quick Stats</h3>
          <div class="space-y-4">
            <div class="flex items-center gap-4 p-5 bg-slate-50 rounded-2xl">
              <div class="w-14 h-14 bg-blue-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-flag" class="w-7 h-7 text-blue-600" />
              </div>
              <div>
                <p class="text-3xl font-extrabold text-slate-900">{length(@all_goals)}</p>
                <p class="text-xs text-slate-400 font-medium">Total Goals</p>
              </div>
            </div>
            <div class="flex items-center gap-4 p-5 bg-slate-50 rounded-2xl">
              <div class="w-14 h-14 bg-green-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-check-circle" class="w-7 h-7 text-green-500" />
              </div>
              <div>
                <p class="text-3xl font-extrabold text-slate-900">
                  {Enum.count(@all_goals, &(&1.status == :active))}
                </p>
                <p class="text-xs text-slate-400 font-medium">Active Goals</p>
              </div>
            </div>
            <div class="flex items-center gap-4 p-5 bg-slate-50 rounded-2xl">
              <div class="w-14 h-14 bg-indigo-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-trophy" class="w-7 h-7 text-indigo-500" />
              </div>
              <div>
                <p class="text-3xl font-extrabold text-slate-900">
                  {Enum.count(@all_goals, &(&1.status == :completed))}
                </p>
                <p class="text-xs text-slate-400 font-medium">Completed</p>
              </div>
            </div>
          </div>
        </section>

        <%!-- Categories --%>
        <section>
          <HeadsUpWeb.Components.UI.SectionHeader.section_header
            title="Categories"
            link_text="View all"
            link_to={~p"/goals-category"}
          />
          <%= if @categories == [] do %>
            <p class="text-sm text-slate-400">No categories yet</p>
          <% else %>
            <div class="grid grid-cols-2 gap-4">
              <%= for category <- Enum.take(@categories, 6) do %>
                <button
                  phx-click="filter_category"
                  phx-value-category-id={category.id}
                  class={[
                    "p-6 rounded-[32px] flex flex-col items-center justify-center text-center cursor-pointer hover:scale-105 transition-transform soft-shadow",
                    (@active_category == category.id && "bg-blue-50 ring-2 ring-blue-500") ||
                      "bg-indigo-50"
                  ]}
                >
                  <div class="w-14 h-14 bg-white rounded-full flex items-center justify-center mb-3 shadow-sm">
                    <.icon name="hero-flag" class="w-6 h-6 text-blue-500" />
                  </div>
                  <span class="font-extrabold text-slate-900 text-sm">{category.name}</span>
                </button>
              <% end %>
            </div>
          <% end %>
        </section>

        <%!-- Create Goal Promo --%>
        <%= if @current_user do %>
          <div class="bg-gradient-to-br from-blue-600 to-indigo-700 p-6 rounded-3xl relative overflow-hidden shadow-lg shadow-blue-500/20">
            <div class="relative z-10">
              <p class="text-white font-bold leading-tight mb-2">Create a Goal</p>
              <p class="text-blue-200 text-xs mb-4">Track progress & build momentum</p>
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
