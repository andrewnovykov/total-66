defmodule HeadsUpWeb.GoalCategoryLive.Show do
  use HeadsUpWeb, :live_view
  alias HeadsUp.{Groups, Goals, Accounts}

  def mount(%{"id" => group_id}, _session, socket) do
    try do
      {group_id, _} = Integer.parse(group_id)
      group = Groups.get_group!(group_id)

      goal_counts = Goals.goal_counts(group_id)
      group_with_counts = Map.merge(group, goal_counts)

      current_user = socket.assigns[:current_user]
      current_user_id = if current_user, do: current_user.id, else: nil

      goals =
        Goals.list_goals_by_group(group_id)
        |> HeadsUp.Repo.preload([:user, :group, :goal_likes, :goal_subscriptions, :goal_posts])
        |> Goals.add_social_counts()

      socket =
        socket
        |> assign(:group, group_with_counts)
        |> assign(:all_goals, goals)
        |> assign(:goals, goals)
        |> assign(:filter_status, "all")
        |> assign(:current_user_id, current_user_id)

      {:ok, socket}
    rescue
      Ecto.NoResultsError ->
        {:ok,
         socket
         |> put_flash(:error, "Goal category not found")
         |> push_navigate(to: ~p"/goals-category")}
    end
  end

  def handle_event("filter_status", %{"status" => status}, socket) do
    filtered =
      case status do
        "all" -> socket.assigns.all_goals
        s -> Enum.filter(socket.assigns.all_goals, &(&1.status == String.to_atom(s)))
      end

    {:noreply,
     socket
     |> assign(:goals, filtered)
     |> assign(:filter_status, status)}
  end

  def handle_event("toggle_like", %{"goal-id" => goal_id}, socket) do
    {goal_id, _} = Integer.parse(goal_id)
    current_user_id = socket.assigns.current_user_id

    if current_user_id do
      if Goals.user_liked_goal?(goal_id, current_user_id) do
        Goals.unlike_goal(goal_id, current_user_id)
      else
        Goals.like_goal(goal_id, current_user_id)
      end

      goals =
        Goals.list_goals_by_group(socket.assigns.group.id)
        |> HeadsUp.Repo.preload([:user, :group, :goal_likes, :goal_subscriptions, :goal_posts])
        |> Goals.add_social_counts()

      filtered =
        case socket.assigns.filter_status do
          "all" -> goals
          s -> Enum.filter(goals, &(&1.status == String.to_atom(s)))
        end

      {:noreply,
       socket
       |> assign(:all_goals, goals)
       |> assign(:goals, filtered)}
    else
      {:noreply, put_flash(socket, :error, "You must be logged in to like goals")}
    end
  end

  def handle_event("toggle_subscribe", %{"goal-id" => goal_id}, socket) do
    {goal_id, _} = Integer.parse(goal_id)
    current_user_id = socket.assigns.current_user_id

    if current_user_id do
      if Goals.user_subscribed_to_goal?(goal_id, current_user_id) do
        Goals.unsubscribe_from_goal(goal_id, current_user_id)
      else
        Goals.subscribe_to_goal(goal_id, current_user_id)
      end

      goals =
        Goals.list_goals_by_group(socket.assigns.group.id)
        |> HeadsUp.Repo.preload([:user, :group, :goal_likes, :goal_subscriptions, :goal_posts])
        |> Goals.add_social_counts()

      filtered =
        case socket.assigns.filter_status do
          "all" -> goals
          s -> Enum.filter(goals, &(&1.status == String.to_atom(s)))
        end

      {:noreply,
       socket
       |> assign(:all_goals, goals)
       |> assign(:goals, filtered)}
    else
      {:noreply, put_flash(socket, :error, "You must be logged in to subscribe to goals")}
    end
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
        <%!-- Hero Banner with Category Info --%>
        <div class="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-[40px] p-8 sm:p-10 lg:p-12 mb-10 relative overflow-hidden text-white soft-shadow">
          <div class="relative z-10">
            <%!-- Back Link --%>
            <.link
              navigate={~p"/goals-category"}
              class="inline-flex items-center gap-2 text-blue-200 hover:text-white text-sm font-bold mb-6 transition-colors"
            >
              <.icon name="hero-arrow-left" class="w-4 h-4" /> All Categories
            </.link>

            <div class="flex items-start gap-6">
              <%!-- Category Image --%>
              <%= if @group.image_path do %>
                <img
                  src={@group.image_path}
                  alt={@group.name}
                  class="w-20 h-20 sm:w-24 sm:h-24 rounded-2xl object-cover border-4 border-white/20 flex-shrink-0"
                />
              <% else %>
                <div class="w-20 h-20 sm:w-24 sm:h-24 rounded-2xl bg-white/20 backdrop-blur-sm flex items-center justify-center flex-shrink-0 border-4 border-white/20">
                  <span class="text-3xl font-extrabold text-white">
                    {String.first(@group.name) |> String.upcase()}
                  </span>
                </div>
              <% end %>

              <div class="flex-1 min-w-0">
                <h1 class="text-3xl sm:text-4xl font-extrabold mb-2 leading-tight">{@group.name}</h1>
                <%= if @group.description do %>
                  <p class="text-blue-100 text-lg leading-relaxed mb-4">{@group.description}</p>
                <% end %>
                <div class="flex items-center gap-4">
                  <div class="flex items-center gap-2 bg-white/20 backdrop-blur-sm px-4 py-2 rounded-full">
                    <.icon name="hero-flag" class="w-4 h-4" />
                    <span class="font-bold text-sm">{@group.total_goal_amount} goals</span>
                  </div>
                  <div class="flex items-center gap-2 bg-white/20 backdrop-blur-sm px-4 py-2 rounded-full">
                    <.icon name="hero-check-circle" class="w-4 h-4" />
                    <span class="font-bold text-sm">{@group.active_goal_amount} active</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div class="absolute right-0 top-0 h-full w-1/3 opacity-10 pointer-events-none flex items-center justify-center">
            <.icon name="hero-user-group" class="w-48 h-48 lg:w-64 lg:h-64" />
          </div>
        </div>

        <%!-- Filter + Results Header --%>
        <section>
          <div class="flex items-center justify-between mb-8">
            <div>
              <h2 class="text-2xl font-extrabold text-slate-900">Goals</h2>
              <p class="text-slate-400 text-sm font-medium mt-1">
                {length(@goals)} {if length(@goals) == 1, do: "goal", else: "goals"} in this category
              </p>
            </div>
            <div class="flex gap-3">
              <button
                phx-click="filter_status"
                phx-value-status="all"
                class={[
                  "px-6 py-2.5 rounded-xl text-sm font-bold transition-all",
                  (@filter_status == "all" && "bg-slate-900 text-white") ||
                    "bg-white text-slate-500 soft-shadow"
                ]}
              >
                All
              </button>
              <button
                phx-click="filter_status"
                phx-value-status="active"
                class={[
                  "px-6 py-2.5 rounded-xl text-sm font-bold transition-all",
                  (@filter_status == "active" && "bg-slate-900 text-white") ||
                    "bg-white text-slate-500 soft-shadow"
                ]}
              >
                Active
              </button>
              <button
                phx-click="filter_status"
                phx-value-status="completed"
                class={[
                  "px-6 py-2.5 rounded-xl text-sm font-bold transition-all hidden sm:block",
                  (@filter_status == "completed" && "bg-slate-900 text-white") ||
                    "bg-white text-slate-500 soft-shadow"
                ]}
              >
                Completed
              </button>
            </div>
          </div>

          <%!-- Goals Feed --%>
          <%= if Enum.empty?(@goals) do %>
            <HeadsUpWeb.Components.UI.EmptyState.empty_state
              icon="hero-flag"
              title="No goals found"
              message="No goals match your current filter. Try a different filter or be the first to create a goal in this category!"
            >
              <:action>
                <.link
                  navigate={~p"/goals/new"}
                  class="inline-flex items-center gap-2 bg-gradient-to-r from-blue-500 to-indigo-600 text-white text-sm font-bold px-6 py-3 rounded-xl transition-colors shadow-lg shadow-blue-500/20"
                >
                  Create Goal
                </.link>
              </:action>
            </HeadsUpWeb.Components.UI.EmptyState.empty_state>
          <% else %>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
              <%= for goal <- @goals do %>
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
                              {@group.name}
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
        <%!-- Category Stats --%>
        <section>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Category Stats</h3>
          <div class="space-y-4">
            <div class="flex items-center gap-4 p-5 bg-slate-50 rounded-2xl">
              <div class="w-14 h-14 bg-blue-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-flag" class="w-7 h-7 text-blue-600" />
              </div>
              <div>
                <p class="text-3xl font-extrabold text-slate-900">{@group.total_goal_amount}</p>
                <p class="text-xs text-slate-400 font-medium">Total Goals</p>
              </div>
            </div>
            <div class="flex items-center gap-4 p-5 bg-slate-50 rounded-2xl">
              <div class="w-14 h-14 bg-green-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-check-circle" class="w-7 h-7 text-green-500" />
              </div>
              <div>
                <p class="text-3xl font-extrabold text-slate-900">{@group.active_goal_amount}</p>
                <p class="text-xs text-slate-400 font-medium">Active Goals</p>
              </div>
            </div>
            <div class="flex items-center gap-4 p-5 bg-slate-50 rounded-2xl">
              <div class="w-14 h-14 bg-indigo-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-users" class="w-7 h-7 text-indigo-500" />
              </div>
              <div>
                <p class="text-3xl font-extrabold text-slate-900">{length(@all_goals)}</p>
                <p class="text-xs text-slate-400 font-medium">Currently Showing</p>
              </div>
            </div>
          </div>
        </section>

        <%!-- Browse Other Categories --%>
        <section>
          <HeadsUpWeb.Components.UI.SectionHeader.section_header
            title="Browse"
            link_text="All Categories"
            link_to={~p"/goals-category"}
          />
          <div class="space-y-3">
            <.link
              navigate={~p"/all-goals"}
              class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors"
            >
              <div class="w-12 h-12 bg-blue-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-fire" class="w-6 h-6 text-blue-500" />
              </div>
              <div class="flex-1">
                <h5 class="font-bold text-slate-900 text-sm">All Goals</h5>
                <p class="text-slate-400 text-xs">Browse every goal</p>
              </div>
              <.icon name="hero-chevron-right" class="w-4 h-4 text-slate-400" />
            </.link>
            <.link
              navigate={~p"/goals-category"}
              class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors"
            >
              <div class="w-12 h-12 bg-indigo-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-squares-2x2" class="w-6 h-6 text-indigo-500" />
              </div>
              <div class="flex-1">
                <h5 class="font-bold text-slate-900 text-sm">All Categories</h5>
                <p class="text-slate-400 text-xs">View other categories</p>
              </div>
              <.icon name="hero-chevron-right" class="w-4 h-4 text-slate-400" />
            </.link>
          </div>
        </section>

        <%!-- Create Goal Promo --%>
        <%= if @current_user do %>
          <div class="bg-gradient-to-br from-blue-600 to-indigo-700 p-6 rounded-3xl relative overflow-hidden shadow-lg shadow-blue-500/20">
            <div class="relative z-10">
              <p class="text-white font-bold leading-tight mb-2">Create a Goal</p>
              <p class="text-blue-200 text-xs mb-4">Add a goal to this category</p>
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
