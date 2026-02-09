defmodule HeadsUpWeb.MyGoalsLive.Index do
  use HeadsUpWeb, :live_view
  alias HeadsUp.Goals
  import HeadsUpWeb.Helpers.SubscriptionHelper

  def mount(_params, _session, socket) do
    current_user_id = socket.assigns.current_user.id
    current_user = socket.assigns.current_user

    my_goals = Goals.list_goals_by_user(current_user_id)
    deleted_goals = Goals.list_deleted_goals_by_user(current_user_id)

    socket =
      socket
      |> assign(:my_goals, my_goals)
      |> assign(:deleted_goals, deleted_goals)
      |> assign(:current_user_id, current_user_id)
      |> assign(:show_deleted, false)
      |> assign(:filter_status, "all")
      |> maybe_show_limit_message(current_user, length(my_goals))

    {:ok, socket}
  end

  defp maybe_show_limit_message(socket, user, goal_count) do
    if not can_create_goal?(user, goal_count) do
      limit = get_goal_limit(user)

      limit_text =
        case limit do
          :unlimited -> "unlimited"
          n -> "#{n}"
        end

      subscription_name = get_subscription_display_name(user.subscription_type)

      socket
      |> put_flash(
        :info,
        "You have reached your goal limit of #{limit_text} goals with your #{subscription_name} subscription. Upgrade to create more goals!"
      )
    else
      socket
    end
  end

  def handle_event("show_upgrade_message", _params, socket) do
    current_user = socket.assigns.current_user
    my_goals = socket.assigns.my_goals

    if not can_create_goal?(current_user, length(my_goals)) do
      limit = get_goal_limit(current_user)

      limit_text =
        case limit do
          :unlimited -> "unlimited"
          n -> "#{n}"
        end

      subscription_name = get_subscription_display_name(current_user.subscription_type)

      socket =
        socket
        |> put_flash(
          :error,
          "You have reached your goal limit of #{limit_text} goals with your #{subscription_name} subscription. Please upgrade to create more goals!"
        )

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("toggle_deleted_goals", _params, socket) do
    {:noreply, assign(socket, :show_deleted, not socket.assigns.show_deleted)}
  end

  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply, assign(socket, :filter_status, status)}
  end

  def handle_event("restore_goal", %{"goal-id" => goal_id}, socket) do
    {goal_id, _} = Integer.parse(goal_id)

    deleted_goal = Enum.find(socket.assigns.deleted_goals, &(&1.id == goal_id))

    if deleted_goal do
      case Goals.restore_goal_with_ownership(deleted_goal, socket.assigns.current_user_id) do
        {:ok, _restored_goal} ->
          {:noreply, refresh_goals(socket, "Goal has been restored successfully!")}

        {:error, :unauthorized} ->
          {:noreply, put_flash(socket, :error, "You are not authorized to restore this goal")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to restore goal")}
      end
    else
      {:noreply, put_flash(socket, :error, "Goal not found")}
    end
  end

  def handle_event("freeze_goal", %{"goal-id" => goal_id}, socket) do
    {goal_id, _} = Integer.parse(goal_id)
    goal = Goals.get_goal!(goal_id)

    case Goals.freeze_goal_with_ownership(goal, socket.assigns.current_user_id) do
      {:ok, _} ->
        {:noreply, refresh_goals(socket, "Goal frozen successfully")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You are not authorized to freeze this goal")}

      {:error, :failed} ->
        {:noreply, put_flash(socket, :error, "Cannot freeze a failed goal")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to freeze goal")}
    end
  end

  def handle_event("unfreeze_goal", %{"goal-id" => goal_id}, socket) do
    {goal_id, _} = Integer.parse(goal_id)
    goal = Goals.get_goal!(goal_id)

    case Goals.unfreeze_goal_with_ownership(goal, socket.assigns.current_user_id) do
      {:ok, _} ->
        {:noreply, refresh_goals(socket, "Goal unfrozen successfully")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You are not authorized to unfreeze this goal")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to unfreeze goal")}
    end
  end

  def handle_event("delete_goal", %{"goal-id" => goal_id}, socket) do
    {goal_id, _} = Integer.parse(goal_id)
    goal = Goals.get_goal!(goal_id)

    case Goals.soft_delete_goal_with_ownership(goal, socket.assigns.current_user_id) do
      {:ok, _} ->
        {:noreply, refresh_goals(socket, "Goal deleted successfully")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You are not authorized to delete this goal")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete goal")}
    end
  end

  def handle_event("fail_goal", %{"goal-id" => goal_id}, socket) do
    {goal_id, _} = Integer.parse(goal_id)
    goal = Goals.get_goal!(goal_id)

    case Goals.fail_goal_with_ownership(
           goal,
           "Marked as failed from dashboard",
           socket.assigns.current_user_id
         ) do
      {:ok, _} ->
        {:noreply, refresh_goals(socket, "Goal marked as failed")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You are not authorized to fail this goal")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update goal")}
    end
  end

  defp refresh_goals(socket, message) do
    current_user_id = socket.assigns.current_user_id
    my_goals = Goals.list_goals_by_user(current_user_id)
    deleted_goals = Goals.list_deleted_goals_by_user(current_user_id)

    socket
    |> assign(:my_goals, my_goals)
    |> assign(:deleted_goals, deleted_goals)
    |> put_flash(:info, message)
  end

  defp filtered_goals(goals, "all"), do: goals

  defp filtered_goals(goals, status) do
    status_atom = String.to_existing_atom(status)
    Enum.filter(goals, &(&1.status == status_atom))
  end

  defp goal_counts(goals) do
    %{
      all: length(goals),
      active: Enum.count(goals, &(&1.status == :active)),
      completed: Enum.count(goals, &(&1.status == :completed)),
      paused: Enum.count(goals, &(&1.status == :paused || &1.status == :frozen))
    }
  end

  defp privacy_icon(:public), do: "hero-globe-alt"
  defp privacy_icon(:friends), do: "hero-user-group"
  defp privacy_icon(_), do: "hero-lock-closed"

  defp privacy_label(:public), do: "Public"
  defp privacy_label(:friends), do: "Friends"
  defp privacy_label(_), do: "Private"

  def render(assigns) do
    assigns =
      assigns
      |> assign(:displayed_goals, filtered_goals(assigns.my_goals, assigns.filter_status))
      |> assign(:counts, goal_counts(assigns.my_goals))

    ~H"""
    <div class="flex gap-0 h-full">
      <%!-- ===== CENTER CONTENT ===== --%>
      <div class="flex-grow p-5 sm:p-8 lg:p-10 overflow-y-auto custom-scrollbar">
        <%!-- Hero Banner --%>
        <div class="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-[40px] p-8 sm:p-10 lg:p-12 mb-10 relative overflow-hidden text-white soft-shadow">
          <div class="relative z-10">
            <span class="bg-blue-500/50 text-blue-100 text-xs font-bold px-4 py-1.5 rounded-full mb-5 inline-block uppercase tracking-wider">
              Dashboard
            </span>
            <h1 class="text-3xl sm:text-4xl lg:text-5xl font-extrabold mb-4 leading-tight">
              My Goals
            </h1>
            <p class="text-blue-100 text-lg mb-6 leading-relaxed max-w-xl">
              {length(@my_goals)} of {case get_goal_limit(@current_user) do
                :unlimited -> "unlimited"
                limit -> limit
              end} goals used · {get_subscription_display_name(@current_user.subscription_type)}
            </p>

            <div class="flex flex-wrap items-center gap-4">
              <%= if can_create_goal?(@current_user, length(@my_goals)) do %>
                <.link
                  navigate={~p"/goals/new"}
                  class="inline-flex items-center gap-2 bg-white text-blue-600 px-8 py-4 rounded-2xl font-bold text-base hover:scale-105 transition-transform shadow-lg"
                >
                  <.icon name="hero-plus" class="w-5 h-5" /> Create Goal
                </.link>
              <% else %>
                <button
                  phx-click="show_upgrade_message"
                  class="inline-flex items-center gap-2 bg-white/30 text-white/70 px-8 py-4 rounded-2xl font-bold text-base cursor-not-allowed"
                >
                  <.icon name="hero-plus" class="w-5 h-5" /> Create Goal
                </button>
              <% end %>
            </div>
          </div>
          <div class="absolute right-0 top-0 h-full w-1/3 opacity-10 pointer-events-none flex items-center justify-center">
            <.icon name="hero-flag" class="w-48 h-48 lg:w-64 lg:h-64" />
          </div>
        </div>

        <%!-- Filter Pills + Results Header --%>
        <div class="flex flex-wrap items-center justify-between mb-8 gap-4">
          <div>
            <h2 class="text-2xl font-extrabold text-slate-900">
              {case @filter_status do
                "all" -> "All Goals"
                "active" -> "Active Goals"
                "completed" -> "Completed Goals"
                "paused" -> "Paused Goals"
                _ -> "Goals"
              end}
            </h2>
            <p class="text-slate-400 text-sm mt-1">{length(@displayed_goals)} goals</p>
          </div>
          <div class="flex gap-3">
            <button
              phx-click="filter_status"
              phx-value-status="all"
              class={"px-6 py-2.5 rounded-xl text-sm font-bold transition-colors #{if @filter_status == "all", do: "bg-slate-900 text-white", else: "bg-white text-slate-500 soft-shadow"}"}
            >
              All ({@counts.all})
            </button>
            <button
              phx-click="filter_status"
              phx-value-status="active"
              class={"px-6 py-2.5 rounded-xl text-sm font-bold transition-colors #{if @filter_status == "active", do: "bg-slate-900 text-white", else: "bg-white text-slate-500 soft-shadow"}"}
            >
              Active ({@counts.active})
            </button>
            <button
              phx-click="filter_status"
              phx-value-status="completed"
              class={"hidden sm:block px-6 py-2.5 rounded-xl text-sm font-bold transition-colors #{if @filter_status == "completed", do: "bg-slate-900 text-white", else: "bg-white text-slate-500 soft-shadow"}"}
            >
              Completed ({@counts.completed})
            </button>
          </div>
        </div>

        <%!-- Goals Feed --%>
        <%= if Enum.empty?(@displayed_goals) do %>
          <HeadsUpWeb.Components.UI.EmptyState.empty_state
            icon="hero-flag"
            title={if @filter_status == "all", do: "No goals yet", else: "No #{@filter_status} goals"}
            message={
              if @filter_status == "all",
                do: "Create your first goal and start tracking your progress.",
                else: "No goals match the selected filter."
            }
          >
            <:action>
              <%= if @filter_status == "all" and can_create_goal?(@current_user, length(@my_goals)) do %>
                <.link
                  navigate={~p"/goals/new"}
                  class="inline-flex items-center gap-2 bg-gradient-to-r from-blue-500 to-indigo-600 text-white text-sm font-bold px-6 py-3 rounded-xl transition-colors shadow-lg shadow-blue-500/20"
                >
                  <.icon name="hero-plus" class="w-4 h-4" /> Create Goal
                </.link>
              <% end %>
              <%= if @filter_status != "all" do %>
                <button
                  phx-click="filter_status"
                  phx-value-status="all"
                  class="text-blue-600 font-bold text-sm hover:text-blue-800 transition-colors"
                >
                  Show All Goals
                </button>
              <% end %>
            </:action>
          </HeadsUpWeb.Components.UI.EmptyState.empty_state>
        <% else %>
          <div class="space-y-6">
            <%= for goal <- @displayed_goals do %>
              <HeadsUpWeb.Components.UI.Card.card hover>
                <div class="flex flex-col sm:flex-row gap-6">
                  <%!-- Goal Image --%>
                  <.link
                    navigate={~p"/goals/#{goal.id}"}
                    class="w-full sm:w-40 h-40 sm:h-32 flex-shrink-0 rounded-2xl overflow-hidden block"
                  >
                    <%= if goal.image_path do %>
                      <img src={goal.image_path} alt={goal.title} class="w-full h-full object-cover" />
                    <% else %>
                      <div class="w-full h-full bg-gradient-to-br from-blue-400 to-indigo-500 flex items-center justify-center">
                        <.icon name="hero-flag" class="w-10 h-10 text-white/80" />
                      </div>
                    <% end %>
                  </.link>

                  <%!-- Goal Content --%>
                  <div class="flex-1 min-w-0">
                    <div class="flex flex-wrap items-center gap-2 mb-3">
                      <HeadsUpWeb.Components.UI.StatusBadge.status_badge
                        status={goal.status}
                        size={:sm}
                      />
                      <span class="bg-slate-100 text-slate-600 text-xs font-bold px-3 py-1 rounded-full inline-flex items-center gap-1">
                        <.icon name={privacy_icon(goal.privacy)} class="w-3 h-3" />
                        {privacy_label(goal.privacy)}
                      </span>
                      <%= if goal.group do %>
                        <span class="bg-blue-50 text-blue-600 text-xs font-bold px-3 py-1 rounded-full">
                          {goal.group.name}
                        </span>
                      <% end %>
                    </div>

                    <.link navigate={~p"/goals/#{goal.id}"} class="block">
                      <p class="text-lg font-extrabold text-slate-900 mb-1 line-clamp-1 hover:text-blue-600 transition-colors">
                        {goal.title}
                      </p>
                    </.link>
                    <p class="text-slate-500 text-sm line-clamp-2 mb-4">{goal.description}</p>

                    <%!-- Progress --%>
                    <div class="flex items-center gap-4 mb-3">
                      <div class="flex-1">
                        <HeadsUpWeb.Components.UI.ProgressBar.progress_bar
                          value={goal.progress}
                          color={:indigo}
                          size={:md}
                        />
                      </div>
                      <span class="text-sm font-bold text-slate-700">{goal.progress}%</span>
                      <%= if goal.target_date do %>
                        <span class="text-xs text-slate-400 hidden sm:inline">
                          <.icon name="hero-calendar" class="w-3 h-3 inline" />
                          {Calendar.strftime(goal.target_date, "%b %d")}
                        </span>
                      <% end %>
                    </div>

                    <%!-- Quick Actions --%>
                    <div class="flex flex-wrap items-center gap-2 pt-2 border-t border-slate-100">
                      <%= if goal.status not in [:failed, :completed, :deleted] do %>
                        <.link
                          navigate={~p"/goals/#{goal.id}/edit"}
                          class="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-bold text-slate-600 bg-slate-100 rounded-lg hover:bg-slate-200 transition-colors"
                        >
                          <.icon name="hero-pencil-square" class="w-3.5 h-3.5" /> Edit
                        </.link>
                      <% end %>

                      <%= if goal.status == :active do %>
                        <button
                          phx-click="freeze_goal"
                          phx-value-goal-id={goal.id}
                          class="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-bold text-blue-600 bg-blue-50 rounded-lg hover:bg-blue-100 transition-colors"
                        >
                          <.icon name="hero-pause" class="w-3.5 h-3.5" /> Freeze
                        </button>
                      <% end %>

                      <%= if goal.status in [:paused, :frozen] do %>
                        <button
                          phx-click="unfreeze_goal"
                          phx-value-goal-id={goal.id}
                          class="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-bold text-green-600 bg-green-50 rounded-lg hover:bg-green-100 transition-colors"
                        >
                          <.icon name="hero-play" class="w-3.5 h-3.5" /> Unfreeze
                        </button>
                      <% end %>

                      <%= if goal.status in [:active, :paused, :frozen] do %>
                        <button
                          phx-click="fail_goal"
                          phx-value-goal-id={goal.id}
                          data-confirm="Are you sure you want to mark this goal as failed?"
                          class="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-bold text-amber-600 bg-amber-50 rounded-lg hover:bg-amber-100 transition-colors"
                        >
                          <.icon name="hero-x-circle" class="w-3.5 h-3.5" /> Fail
                        </button>
                      <% end %>

                      <button
                        phx-click="delete_goal"
                        phx-value-goal-id={goal.id}
                        data-confirm="Are you sure you want to delete this goal?"
                        class="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-bold text-red-600 bg-red-50 rounded-lg hover:bg-red-100 transition-colors ml-auto"
                      >
                        <.icon name="hero-trash" class="w-3.5 h-3.5" /> Delete
                      </button>
                    </div>
                  </div>
                </div>
              </HeadsUpWeb.Components.UI.Card.card>
            <% end %>
          </div>
        <% end %>

        <%!-- Deleted Goals Section --%>
        <%= if length(@deleted_goals) > 0 do %>
          <div class="mt-12">
            <div class="flex items-center justify-between mb-6">
              <div>
                <h2 class="text-xl font-extrabold text-slate-900">Deleted Goals</h2>
                <p class="text-slate-400 text-sm">{length(@deleted_goals)} deleted goals</p>
              </div>
              <button
                phx-click="toggle_deleted_goals"
                class="inline-flex items-center gap-2 px-5 py-2.5 bg-slate-100 text-slate-600 rounded-xl text-sm font-bold hover:bg-slate-200 transition-colors"
              >
                <%= if @show_deleted do %>
                  <.icon name="hero-eye-slash" class="w-4 h-4" /> Hide
                <% else %>
                  <.icon name="hero-eye" class="w-4 h-4" /> Show
                <% end %>
              </button>
            </div>

            <%= if @show_deleted do %>
              <div class="space-y-4">
                <div
                  :for={goal <- @deleted_goals}
                  class="bg-slate-50 rounded-[40px] p-8 border border-slate-100 opacity-75"
                >
                  <div class="flex flex-col sm:flex-row gap-6">
                    <%!-- Deleted Goal Image --%>
                    <div class="w-full sm:w-32 h-32 flex-shrink-0 rounded-2xl overflow-hidden">
                      <%= if goal.image_path do %>
                        <img
                          src={goal.image_path}
                          alt={goal.title}
                          class="w-full h-full object-cover grayscale"
                        />
                      <% else %>
                        <div class="w-full h-full bg-gradient-to-br from-slate-300 to-slate-400 flex items-center justify-center">
                          <.icon name="hero-trash" class="w-8 h-8 text-white/80" />
                        </div>
                      <% end %>
                    </div>

                    <%!-- Deleted Goal Content --%>
                    <div class="flex-1 min-w-0">
                      <span class="bg-red-50 text-red-600 text-xs font-bold px-3 py-1 rounded-full mb-3 inline-block">
                        Deleted
                      </span>
                      <p class="text-lg font-extrabold text-slate-900 mb-1">{goal.title}</p>
                      <p class="text-slate-500 text-sm line-clamp-2 mb-2">{goal.description}</p>
                      <p class="text-slate-400 text-xs mb-4">
                        Deleted on: {Calendar.strftime(goal.deleted_at, "%b %d, %Y at %I:%M %p")}
                      </p>
                      <%= if goal.group do %>
                        <span class="text-slate-400 text-xs">
                          <.icon name="hero-tag" class="w-3 h-3 inline" /> {goal.group.name}
                        </span>
                      <% end %>

                      <div class="mt-4">
                        <button
                          phx-click="restore_goal"
                          phx-value-goal-id={goal.id}
                          data-confirm="Are you sure you want to restore this goal? It will be moved back to your active goals."
                          class="inline-flex items-center gap-2 bg-gradient-to-r from-green-500 to-emerald-600 text-white px-6 py-3 rounded-xl text-sm font-bold hover:scale-[1.02] transition-transform shadow-lg"
                        >
                          <.icon name="hero-arrow-path" class="w-4 h-4" /> Restore Goal
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>

      <%!-- ===== RIGHT SIDEBAR ===== --%>
      <aside class="hidden xl:flex flex-col w-[420px] flex-shrink-0 bg-white border-l border-slate-100 p-8 overflow-y-auto custom-scrollbar gap-10">
        <%!-- Goal Overview Stats --%>
        <div>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Overview</h3>
          <div class="space-y-3">
            <div class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl">
              <div class="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-flag" class="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <p class="text-sm text-slate-500">Total Goals</p>
                <p class="font-extrabold text-slate-900">{length(@my_goals)}</p>
              </div>
            </div>
            <div class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl">
              <div class="w-10 h-10 bg-green-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-check-circle" class="w-5 h-5 text-green-600" />
              </div>
              <div>
                <p class="text-sm text-slate-500">Active</p>
                <p class="font-extrabold text-slate-900">{@counts.active}</p>
              </div>
            </div>
            <div class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl">
              <div class="w-10 h-10 bg-indigo-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-trophy" class="w-5 h-5 text-indigo-600" />
              </div>
              <div>
                <p class="text-sm text-slate-500">Completed</p>
                <p class="font-extrabold text-slate-900">{@counts.completed}</p>
              </div>
            </div>
          </div>
        </div>

        <%!-- Subscription Info --%>
        <div>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Subscription</h3>
          <div class="bg-gradient-to-br from-blue-500 to-indigo-600 rounded-2xl p-6 text-white">
            <p class="text-blue-100 text-sm font-medium mb-1">Current Plan</p>
            <p class="text-xl font-extrabold mb-3">
              {get_subscription_display_name(@current_user.subscription_type)}
            </p>
            <div class="flex items-center gap-2">
              <div class="flex-1 bg-white/20 rounded-full h-2">
                <div
                  class="bg-white rounded-full h-2 transition-all duration-300"
                  style={"width: #{case get_goal_limit(@current_user) do
                    :unlimited -> 0
                    limit -> min(100, round(length(@my_goals) / limit * 100))
                  end}%"}
                >
                </div>
              </div>
              <span class="text-sm font-bold text-blue-100">
                {length(@my_goals)} / {case get_goal_limit(@current_user) do
                  :unlimited -> "∞"
                  limit -> limit
                end}
              </span>
            </div>
          </div>
        </div>

        <%!-- Quick Links --%>
        <div>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Quick Links</h3>
          <div class="space-y-3">
            <.link
              navigate={~p"/all-goals"}
              class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors group"
            >
              <div class="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-fire" class="w-5 h-5 text-blue-600" />
              </div>
              <span class="font-bold text-slate-700 group-hover:text-slate-900">
                Browse All Goals
              </span>
              <.icon name="hero-chevron-right" class="w-5 h-5 text-slate-400 ml-auto" />
            </.link>
            <.link
              navigate={~p"/my-challenges"}
              class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors group"
            >
              <div class="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-bolt" class="w-5 h-5 text-blue-600" />
              </div>
              <span class="font-bold text-slate-700 group-hover:text-slate-900">My Challenges</span>
              <.icon name="hero-chevron-right" class="w-5 h-5 text-slate-400 ml-auto" />
            </.link>
            <.link
              navigate={~p"/goals-category"}
              class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors group"
            >
              <div class="w-10 h-10 bg-indigo-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-squares-2x2" class="w-5 h-5 text-indigo-600" />
              </div>
              <span class="font-bold text-slate-700 group-hover:text-slate-900">Goal Categories</span>
              <.icon name="hero-chevron-right" class="w-5 h-5 text-slate-400 ml-auto" />
            </.link>
          </div>
        </div>

        <%!-- Create Goal Promo (when can still create) --%>
        <%= if can_create_goal?(@current_user, length(@my_goals)) do %>
          <div class="bg-gradient-to-br from-blue-600 to-indigo-700 rounded-2xl p-6 text-white">
            <.icon name="hero-rocket-launch" class="w-8 h-8 text-blue-200 mb-3" />
            <p class="font-bold leading-tight mb-2">Ready for a new goal?</p>
            <p class="text-blue-200 text-xs mb-4">Track progress & build momentum</p>
            <.link
              navigate={~p"/goals/new"}
              class="inline-block bg-white text-blue-600 text-xs font-bold px-5 py-2.5 rounded-xl hover:bg-blue-50 transition-colors"
            >
              Create Goal
            </.link>
          </div>
        <% end %>
      </aside>
    </div>
    """
  end
end
