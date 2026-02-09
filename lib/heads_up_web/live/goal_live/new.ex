defmodule HeadsUpWeb.GoalLive.New do
  use HeadsUpWeb, :live_view
  alias HeadsUp.Goals
  alias HeadsUp.Goal
  alias HeadsUp.Groups
  import HeadsUpWeb.Helpers.SubscriptionHelper

  def mount(_params, _session, socket) do
    # Check if user is authenticated
    current_user = socket.assigns[:current_user]

    if is_nil(current_user) do
      socket =
        socket
        |> put_flash(:error, "You must be logged in to create goals.")
        |> push_navigate(to: ~p"/users/log_in")

      {:ok, socket}
    else
      # Get the authenticated user and check subscription limits
      current_user_id = current_user.id

      # Check subscription-based goal limit
      user_goals = Goals.list_goals_by_user(current_user_id)
      goal_groups = Groups.list_published_groups()

      if not can_create_goal?(current_user, length(user_goals)) do
        limit = get_goal_limit(current_user)

        limit_text =
          case limit do
            :unlimited -> "unlimited"
            n -> "#{n}"
          end

        socket =
          socket
          |> put_flash(
            :error,
            "You can only create up to #{limit_text} goals with your current subscription (#{get_subscription_display_name(current_user.subscription_type)}). Please upgrade or delete an existing goal first."
          )
          |> push_navigate(to: ~p"/my-goals")

        {:ok, socket}
      else
        socket =
          socket
          |> assign(:goal, %Goal{})
          |> assign(:goal_groups, goal_groups)
          |> assign(:current_user_id, current_user_id)
          |> assign(:current_user, current_user)

        {:ok, socket}
      end
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
              navigate={~p"/my-goals"}
              class="inline-flex items-center gap-2 text-blue-200 hover:text-white text-sm font-medium mb-6 transition-colors"
            >
              <.icon name="hero-arrow-left" class="w-4 h-4" /> Back to My Goals
            </.link>

            <span class="bg-blue-500/50 text-blue-100 text-xs font-bold px-4 py-1.5 rounded-full mb-4 inline-block uppercase tracking-wider">
              New Goal
            </span>
            <h1 class="text-3xl sm:text-4xl lg:text-5xl font-extrabold mb-4 leading-tight">
              Create New Goal
            </h1>
            <p class="text-blue-100 text-lg leading-relaxed max-w-xl">
              Set a new goal and start tracking your progress. Break it down into steps and share your journey.
            </p>
          </div>
          <div class="absolute right-0 top-0 h-full w-1/3 opacity-10 pointer-events-none flex items-center justify-center">
            <.icon name="hero-rocket-launch" class="w-48 h-48 lg:w-64 lg:h-64" />
          </div>
        </div>

        <%!-- Form Card --%>
        <HeadsUpWeb.Components.UI.Card.card padding={:lg}>
          <h2 class="text-2xl font-extrabold text-slate-900 mb-2">Goal Details</h2>
          <p class="text-slate-500 mb-8">Fill in the details below to create your new goal.</p>

          <.live_component
            module={HeadsUpWeb.GoalLive.FormComponent}
            id="new-goal"
            action={:new}
            goal={@goal}
            current_user_id={@current_user_id}
            current_user={@current_user}
            goal_groups={@goal_groups}
            patch={~p"/my-goals"}
          />
        </HeadsUpWeb.Components.UI.Card.card>
      </div>

      <%!-- ===== RIGHT SIDEBAR ===== --%>
      <aside class="hidden xl:flex flex-col w-[420px] flex-shrink-0 bg-white border-l border-slate-100 p-8 overflow-y-auto custom-scrollbar gap-10">
        <%!-- Tips --%>
        <div>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Tips for Success</h3>
          <div class="space-y-4">
            <div class="flex items-start gap-4 p-4 bg-slate-50 rounded-2xl">
              <div class="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center flex-shrink-0">
                <.icon name="hero-light-bulb" class="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <p class="font-bold text-slate-900 text-sm">Be Specific</p>
                <p class="text-slate-500 text-sm mt-1">
                  Clear goals are easier to track and achieve.
                </p>
              </div>
            </div>
            <div class="flex items-start gap-4 p-4 bg-slate-50 rounded-2xl">
              <div class="w-10 h-10 bg-green-50 rounded-xl flex items-center justify-center flex-shrink-0">
                <.icon name="hero-calendar" class="w-5 h-5 text-green-600" />
              </div>
              <div>
                <p class="font-bold text-slate-900 text-sm">Set a Deadline</p>
                <p class="text-slate-500 text-sm mt-1">
                  A target date helps you stay motivated and focused.
                </p>
              </div>
            </div>
            <div class="flex items-start gap-4 p-4 bg-slate-50 rounded-2xl">
              <div class="w-10 h-10 bg-indigo-50 rounded-xl flex items-center justify-center flex-shrink-0">
                <.icon name="hero-user-group" class="w-5 h-5 text-indigo-600" />
              </div>
              <div>
                <p class="font-bold text-slate-900 text-sm">Share Publicly</p>
                <p class="text-slate-500 text-sm mt-1">
                  Public goals get community support and accountability.
                </p>
              </div>
            </div>
            <div class="flex items-start gap-4 p-4 bg-slate-50 rounded-2xl">
              <div class="w-10 h-10 bg-amber-50 rounded-xl flex items-center justify-center flex-shrink-0">
                <.icon name="hero-clipboard-document-list" class="w-5 h-5 text-amber-600" />
              </div>
              <div>
                <p class="font-bold text-slate-900 text-sm">Add Steps Later</p>
                <p class="text-slate-500 text-sm mt-1">
                  You can break your goal into steps after creating it.
                </p>
              </div>
            </div>
          </div>
        </div>

        <%!-- Quick Links --%>
        <div>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Quick Links</h3>
          <div class="space-y-3">
            <.link
              navigate={~p"/my-goals"}
              class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors group"
            >
              <div class="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-flag" class="w-5 h-5 text-blue-600" />
              </div>
              <span class="font-bold text-slate-700 group-hover:text-slate-900">My Goals</span>
              <.icon name="hero-chevron-right" class="w-5 h-5 text-slate-400 ml-auto" />
            </.link>
            <.link
              navigate={~p"/all-goals"}
              class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors group"
            >
              <div class="w-10 h-10 bg-indigo-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-fire" class="w-5 h-5 text-indigo-600" />
              </div>
              <span class="font-bold text-slate-700 group-hover:text-slate-900">
                Browse All Goals
              </span>
              <.icon name="hero-chevron-right" class="w-5 h-5 text-slate-400 ml-auto" />
            </.link>
          </div>
        </div>
      </aside>
    </div>
    """
  end
end
