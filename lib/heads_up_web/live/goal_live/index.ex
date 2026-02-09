defmodule HeadsUpWeb.GoalLive.Index do
  use HeadsUpWeb, :live_view
  alias HeadsUp.Goals
  alias HeadsUp.GoalGroups

  def mount(_params, _session, socket) do
    # For demo purposes, using a hardcoded user ID
    # In a real app, this would come from session/authentication
    current_user_id = 1

    user_goals = Goals.list_goals_by_user(current_user_id)
    goal_groups = GoalGroups.get_goal_groups()

    socket =
      socket
      |> assign(:user_goals, user_goals)
      |> assign(:goal_groups, goal_groups)
      |> assign(:current_user_id, current_user_id)
      |> assign(:show_create_form, false)
      |> assign(:filter_status, "all")
      |> assign(:filter_privacy, "all")

    {:ok, socket}
  end

  def handle_event("show_create_form", _params, socket) do
    # Check goal limit (max 2 goals per user)
    user_goals_count = length(socket.assigns.user_goals)

    if user_goals_count >= 2 do
      socket =
        put_flash(
          socket,
          :error,
          "You can only create maximum 2 goals. Please delete an existing goal first."
        )

      {:noreply, socket}
    else
      {:noreply, assign(socket, :show_create_form, true)}
    end
  end

  def handle_event("hide_create_form", _params, socket) do
    {:noreply, assign(socket, :show_create_form, false)}
  end

  def handle_event("filter_status", %{"status" => status}, socket) do
    filtered_goals =
      filter_goals(socket.assigns.user_goals, status, socket.assigns.filter_privacy)

    socket =
      socket
      |> assign(:filtered_goals, filtered_goals)
      |> assign(:filter_status, status)

    {:noreply, socket}
  end

  def handle_event("filter_privacy", %{"privacy" => privacy}, socket) do
    filtered_goals =
      filter_goals(socket.assigns.user_goals, socket.assigns.filter_status, privacy)

    socket =
      socket
      |> assign(:filtered_goals, filtered_goals)
      |> assign(:filter_privacy, privacy)

    {:noreply, socket}
  end

  def handle_event("delete_goal", %{"goal-id" => goal_id}, socket) do
    {goal_id, _} = Integer.parse(goal_id)
    goal = Goals.get_goal!(goal_id)

    # Verify the goal belongs to the current user
    if goal.user_id == socket.assigns.current_user_id do
      case Goals.delete_goal(goal) do
        {:ok, _} ->
          # Refresh the goals list
          user_goals = Goals.list_goals_by_user(socket.assigns.current_user_id)

          socket =
            socket
            |> assign(:user_goals, user_goals)
            |> put_flash(:info, "Goal deleted successfully")

          {:noreply, socket}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to delete goal")}
      end
    else
      {:noreply, put_flash(socket, :error, "You can only delete your own goals")}
    end
  end

  def handle_event("toggle_goal_status", %{"goal-id" => goal_id}, socket) do
    {goal_id, _} = Integer.parse(goal_id)
    goal = Goals.get_goal!(goal_id)

    # Verify the goal belongs to the current user
    if goal.user_id == socket.assigns.current_user_id do
      new_status =
        case goal.status do
          :active -> :paused
          :paused -> :active
          :completed -> :active
          :cancelled -> :active
        end

      case Goals.update_goal(goal, %{status: new_status}) do
        {:ok, _updated_goal} ->
          # Refresh the goals list
          user_goals = Goals.list_goals_by_user(socket.assigns.current_user_id)

          socket =
            socket
            |> assign(:user_goals, user_goals)
            |> put_flash(:info, "Goal status updated")

          {:noreply, socket}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to update goal status")}
      end
    else
      {:noreply, put_flash(socket, :error, "You can only modify your own goals")}
    end
  end

  defp filter_goals(goals, status_filter, privacy_filter) do
    goals
    |> filter_by_status(status_filter)
    |> filter_by_privacy(privacy_filter)
  end

  defp filter_by_status(goals, "all"), do: goals

  defp filter_by_status(goals, status) do
    status_atom = String.to_atom(status)
    Enum.filter(goals, &(&1.status == status_atom))
  end

  defp filter_by_privacy(goals, "all"), do: goals

  defp filter_by_privacy(goals, privacy) do
    privacy_atom = String.to_atom(privacy)
    Enum.filter(goals, &(&1.privacy == privacy_atom))
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <!-- Header -->
      <div class="bg-white shadow-sm border-b">
        <div class="max-w-7xl mx-auto px-4 py-6">
          <div class="flex items-center justify-between mb-6">
            <h1 class="text-3xl font-bold text-[#0d141c]">My Goals</h1>
            <button
              phx-click="show_create_form"
              class="flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5 mr-2"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 4v16m8-8H4"
                />
              </svg>
              Create Goal
              <%= if length(@user_goals) >= 2 do %>
                <span class="ml-2 text-xs bg-red-500 text-white px-2 py-1 rounded">Max reached</span>
              <% end %>
            </button>
          </div>
          
    <!-- Goal Limit Info -->
          <div class="mb-4 p-3 bg-blue-50 border border-blue-200 rounded-lg">
            <p class="text-sm text-blue-800">
              <strong>Goal Limit:</strong> You can create up to 2 goals.
              Currently: <span class="font-medium">{length(@user_goals)}/2</span> goals created.
            </p>
          </div>
          
    <!-- Filters -->
          <div class="flex flex-wrap items-center gap-4 mb-6">
            <div class="flex items-center space-x-2">
              <label class="text-sm font-medium text-[#0d141c]">Status:</label>
              <select
                phx-change="filter_status"
                name="status"
                value={@filter_status}
                class="border border-gray-300 rounded-md px-3 py-1 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="all">All</option>
                <option value="active">Active</option>
                <option value="completed">Completed</option>
                <option value="paused">Paused</option>
                <option value="cancelled">Cancelled</option>
              </select>
            </div>

            <div class="flex items-center space-x-2">
              <label class="text-sm font-medium text-[#0d141c]">Privacy:</label>
              <select
                phx-change="filter_privacy"
                name="privacy"
                value={@filter_privacy}
                class="border border-gray-300 rounded-md px-3 py-1 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="all">All</option>
                <option value="public">Public</option>
                <option value="private">Private</option>
              </select>
            </div>

            <div class="ml-auto text-sm text-[#49739c]">
              Showing {length(@user_goals)} goals
            </div>
          </div>
        </div>
      </div>
      
    <!-- Flash Messages -->
      <%= if Phoenix.Flash.get(@flash, :info) do %>
        <div class="max-w-7xl mx-auto px-4 py-2">
          <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded">
            {Phoenix.Flash.get(@flash, :info)}
          </div>
        </div>
      <% end %>

      <%= if Phoenix.Flash.get(@flash, :error) do %>
        <div class="max-w-7xl mx-auto px-4 py-2">
          <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
            {Phoenix.Flash.get(@flash, :error)}
          </div>
        </div>
      <% end %>
      
    <!-- Create Goal Form Modal -->
      <%= if @show_create_form do %>
        <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div class="bg-white rounded-lg p-6 max-w-2xl w-full mx-4 max-h-screen overflow-y-auto">
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-xl font-semibold">Create New Goal</h2>
              <button phx-click="hide_create_form" class="text-gray-500 hover:text-gray-700">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-6 w-6"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>

            <.live_component
              module={HeadsUpWeb.GoalLive.FormComponent}
              id="create-goal"
              action="new"
              goal={%HeadsUp.Goal{}}
              current_user_id={@current_user_id}
              goal_groups={@goal_groups}
              patch={~p"/my-goals"}
            />
          </div>
        </div>
      <% end %>
      
    <!-- Goals Grid -->
      <div class="max-w-7xl mx-auto px-4 py-8">
        <%= if Enum.empty?(@user_goals) do %>
          <div class="text-center py-12">
            <div class="max-w-md mx-auto">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-16 w-16 mx-auto text-gray-400 mb-4"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="1"
                  d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
                />
              </svg>
              <h3 class="text-lg font-medium text-[#0d141c] mb-2">No goals yet</h3>
              <p class="text-[#49739c] mb-6">
                Create your first goal to start tracking your progress!
              </p>
              <button
                phx-click="show_create_form"
                class="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
              >
                Create Your First Goal
              </button>
            </div>
          </div>
        <% else %>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <div
              :for={goal <- @user_goals}
              class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden hover:shadow-lg transition-all duration-200"
            >
              <!-- Goal Details -->
              <div class="p-4">
                <h3 class="text-lg font-semibold text-[#0d141c] mb-2 line-clamp-2">
                  <.link navigate={~p"/goals/#{goal.id}"} class="hover:text-blue-600">
                    {goal.title}
                  </.link>
                </h3>

                <p class="text-[#49739c] text-sm mb-3 line-clamp-2">
                  {goal.description}
                </p>
                
    <!-- Status and Privacy -->
                <div class="flex items-center gap-2 mb-3">
                  <span class={"px-2 py-1 rounded-full text-xs font-medium #{status_class(goal.status)}"}>
                    {String.capitalize(to_string(goal.status))}
                  </span>
                  <span class={"px-2 py-1 rounded-full text-xs font-medium #{privacy_class(goal.privacy)}"}>
                    <%= if goal.privacy == :public do %>
                      🌐 Public
                    <% else %>
                      🔒 Private
                    <% end %>
                  </span>
                </div>
                
    <!-- Progress -->
                <div class="mb-3">
                  <div class="flex items-center justify-between text-sm text-[#49739c] mb-1">
                    <span>Progress</span>
                    <span class="font-medium text-[#0d141c]">{goal.progress}%</span>
                  </div>
                  <div class="w-full bg-gray-200 rounded-full h-2">
                    <div
                      class="bg-blue-600 h-2 rounded-full transition-all duration-300"
                      style={"width: #{goal.progress}%"}
                    >
                    </div>
                  </div>
                </div>
                
    <!-- Category and Target Date -->
                <div class="space-y-1 text-xs text-[#49739c]">
                  <%= if goal.group do %>
                    <div>Category: <span class="font-medium">{goal.group.name}</span></div>
                  <% end %>
                  <%= if goal.target_date do %>
                    <div>
                      Target:
                      <span class="font-medium">
                        {Calendar.strftime(goal.target_date, "%B %d, %Y")}
                      </span>
                    </div>
                  <% end %>
                </div>
                
    <!-- Action Buttons -->
                <div class="pt-3 border-t border-gray-100 mt-3 space-y-2">
                  <div class="flex items-center justify-between">
                    <.link
                      navigate={~p"/goals/#{goal.id}"}
                      class="text-sm text-blue-600 hover:text-blue-800 font-medium"
                    >
                      View Details →
                    </.link>

                    <.link
                      navigate={~p"/goals/#{goal.id}/edit"}
                      class="text-sm text-gray-600 hover:text-gray-800"
                    >
                      Edit
                    </.link>
                  </div>
                  
    <!-- Quick Actions -->
                  <div class="flex items-center justify-between">
                    <button
                      phx-click="toggle_goal_status"
                      phx-value-goal-id={goal.id}
                      class={"text-xs px-2 py-1 rounded transition-colors #{if goal.status == :active, do: "bg-yellow-100 text-yellow-800 hover:bg-yellow-200", else: "bg-green-100 text-green-800 hover:bg-green-200"}"}
                      title={if goal.status == :active, do: "Pause Goal", else: "Resume Goal"}
                    >
                      {if goal.status == :active, do: "⏸ Pause", else: "▶ Resume"}
                    </button>

                    <button
                      phx-click="delete_goal"
                      phx-value-goal-id={goal.id}
                      data-confirm="Are you sure you want to delete this goal? This action cannot be undone."
                      class="text-xs px-2 py-1 rounded bg-red-100 text-red-800 hover:bg-red-200 transition-colors"
                      title="Delete Goal"
                    >
                      🗑 Delete
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp status_class(:active), do: "bg-green-100 text-green-800"
  defp status_class(:completed), do: "bg-blue-100 text-blue-800"
  defp status_class(:paused), do: "bg-yellow-100 text-yellow-800"
  defp status_class(:cancelled), do: "bg-red-100 text-red-800"
  defp status_class(_), do: "bg-gray-100 text-gray-800"

  defp privacy_class(:public), do: "bg-green-100 text-green-700"
  defp privacy_class(:private), do: "bg-gray-100 text-gray-700"
end
