defmodule HeadsUpWeb.GoalLive.Edit do
  use HeadsUpWeb, :live_view
  alias HeadsUp.Goals
  alias HeadsUp.GoalGroups

  def mount(%{"id" => goal_id}, _session, socket) do
    # Get the authenticated user ID
    current_user_id = socket.assigns.current_user.id

    try do
      {goal_id, _} = Integer.parse(goal_id)
      goal = Goals.get_goal!(goal_id)
      goal_groups = GoalGroups.get_goal_groups()

      # Verify the goal belongs to the current user
      cond do
        goal.user_id != current_user_id ->
          socket =
            socket
            |> put_flash(:error, "You can only edit your own goals")
            |> push_navigate(to: ~p"/my-goals")

          {:ok, socket}

        goal.status in [:failed, :deleted] ->
          socket =
            socket
            |> put_flash(
              :error,
              "#{String.capitalize(to_string(goal.status))} goals cannot be edited"
            )
            |> push_navigate(to: ~p"/my-goals")

          {:ok, socket}

        true ->
          socket =
            socket
            |> assign(:goal, goal)
            |> assign(:goal_groups, goal_groups)
            |> assign(:current_user_id, current_user_id)

          {:ok, socket}
      end
    rescue
      Ecto.NoResultsError ->
        socket =
          socket
          |> put_flash(:error, "Goal not found")
          |> push_navigate(to: ~p"/my-goals")

        {:ok, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="flex gap-0 h-full">
      <%!-- ===== CENTER CONTENT ===== --%>
      <div class="flex-grow p-5 sm:p-8 lg:p-10 overflow-y-auto custom-scrollbar">
        <%!-- Hero Banner --%>
        <div class="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-[40px] p-8 sm:p-10 lg:p-12 mb-10 relative overflow-hidden text-white soft-shadow">
          <div class="relative z-10">
            <%!-- Back link --%>
            <.link
              navigate={~p"/goals/#{@goal.id}"}
              class="inline-flex items-center gap-2 text-blue-200 hover:text-white text-sm font-medium mb-6 transition-colors"
            >
              <.icon name="hero-arrow-left" class="w-4 h-4" /> Back to Goal
            </.link>

            <div class="flex flex-col sm:flex-row sm:items-center gap-6">
              <%!-- Goal Image --%>
              <div class="w-20 sm:w-24 h-20 sm:h-24 flex-shrink-0">
                <%= if @goal.image_path do %>
                  <img
                    src={@goal.image_path}
                    alt={@goal.title}
                    class="w-full h-full object-cover rounded-2xl border-4 border-white/20"
                  />
                <% else %>
                  <div class="w-full h-full bg-white/20 backdrop-blur-sm rounded-2xl flex items-center justify-center border-4 border-white/10">
                    <.icon name="hero-flag" class="w-10 h-10 text-white/80" />
                  </div>
                <% end %>
              </div>

              <div class="flex-1 min-w-0">
                <span class="bg-blue-500/50 text-blue-100 text-xs font-bold px-4 py-1.5 rounded-full mb-3 inline-block uppercase tracking-wider">
                  Edit Goal
                </span>
                <h1 class="text-2xl sm:text-3xl lg:text-4xl font-extrabold leading-tight">
                  {@goal.title}
                </h1>
                <div class="flex flex-wrap items-center gap-3 mt-4">
                  <span class="bg-white/20 backdrop-blur-sm text-white text-sm font-bold px-4 py-1.5 rounded-full">
                    <.icon name="hero-chart-bar" class="w-4 h-4 inline" /> {@goal.progress}%
                  </span>
                  <span class="bg-white/20 backdrop-blur-sm text-white text-sm font-bold px-4 py-1.5 rounded-full">
                    {String.capitalize(to_string(@goal.status))}
                  </span>
                </div>
              </div>
            </div>
          </div>
          <div class="absolute right-0 top-0 h-full w-1/3 opacity-10 pointer-events-none flex items-center justify-center">
            <.icon name="hero-pencil-square" class="w-48 h-48 lg:w-64 lg:h-64" />
          </div>
        </div>

        <%!-- Form Card --%>
        <HeadsUpWeb.Components.UI.Card.card padding={:lg}>
          <h2 class="text-2xl font-extrabold text-slate-900 mb-2">Goal Details</h2>
          <p class="text-slate-500 mb-8">Update your goal information and settings below.</p>

          <.live_component
            module={HeadsUpWeb.GoalLive.FormComponent}
            id="edit-goal"
            action={:edit}
            goal={@goal}
            current_user_id={@current_user_id}
            goal_groups={@goal_groups}
            patch={~p"/my-goals"}
          />
        </HeadsUpWeb.Components.UI.Card.card>
      </div>

      <%!-- ===== RIGHT SIDEBAR ===== --%>
      <aside class="hidden xl:flex flex-col w-[420px] flex-shrink-0 bg-white border-l border-slate-100 p-8 overflow-y-auto custom-scrollbar gap-10">
        <%!-- Current Goal Info --%>
        <div>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Current Goal</h3>

          <div class="bg-slate-50 rounded-2xl p-5">
            <%= if @goal.image_path do %>
              <img
                src={@goal.image_path}
                alt={@goal.title}
                class="w-full h-32 object-cover rounded-xl mb-4"
              />
            <% else %>
              <div class="w-full h-32 bg-gradient-to-br from-blue-400 to-indigo-500 rounded-xl mb-4 flex items-center justify-center">
                <.icon name="hero-flag" class="w-12 h-12 text-white/80" />
              </div>
            <% end %>
            <h4 class="font-extrabold text-slate-900 text-lg">{@goal.title}</h4>
            <%= if @goal.description do %>
              <p class="text-slate-500 text-sm mt-2 line-clamp-3">{@goal.description}</p>
            <% end %>
          </div>
        </div>

        <%!-- Goal Stats --%>
        <div>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Goal Stats</h3>
          <div class="space-y-3">
            <div class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl">
              <div class="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-chart-bar" class="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <p class="text-sm text-slate-500">Progress</p>
                <p class="font-extrabold text-slate-900">{@goal.progress}%</p>
              </div>
            </div>
            <div class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl">
              <div class="w-10 h-10 bg-green-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-check-circle" class="w-5 h-5 text-green-600" />
              </div>
              <div>
                <p class="text-sm text-slate-500">Status</p>
                <p class="font-extrabold text-slate-900">
                  {String.capitalize(to_string(@goal.status))}
                </p>
              </div>
            </div>
            <div class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl">
              <div class="w-10 h-10 bg-indigo-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-eye" class="w-5 h-5 text-indigo-600" />
              </div>
              <div>
                <p class="text-sm text-slate-500">Privacy</p>
                <p class="font-extrabold text-slate-900">
                  {String.capitalize(to_string(@goal.privacy))}
                </p>
              </div>
            </div>
            <%= if @goal.target_date do %>
              <div class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl">
                <div class="w-10 h-10 bg-amber-50 rounded-xl flex items-center justify-center">
                  <.icon name="hero-calendar" class="w-5 h-5 text-amber-600" />
                </div>
                <div>
                  <p class="text-sm text-slate-500">Target Date</p>
                  <p class="font-extrabold text-slate-900">
                    {Calendar.strftime(@goal.target_date, "%b %d, %Y")}
                  </p>
                </div>
              </div>
            <% end %>
          </div>
        </div>

        <%!-- Quick Links --%>
        <div>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Quick Links</h3>
          <div class="space-y-3">
            <.link
              navigate={~p"/goals/#{@goal.id}"}
              class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors group"
            >
              <div class="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-eye" class="w-5 h-5 text-blue-600" />
              </div>
              <span class="font-bold text-slate-700 group-hover:text-slate-900">View Goal</span>
              <.icon name="hero-chevron-right" class="w-5 h-5 text-slate-400 ml-auto" />
            </.link>
            <.link
              navigate={~p"/my-goals"}
              class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors group"
            >
              <div class="w-10 h-10 bg-indigo-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-flag" class="w-5 h-5 text-indigo-600" />
              </div>
              <span class="font-bold text-slate-700 group-hover:text-slate-900">My Goals</span>
              <.icon name="hero-chevron-right" class="w-5 h-5 text-slate-400 ml-auto" />
            </.link>
          </div>
        </div>
      </aside>
    </div>
    """
  end
end
