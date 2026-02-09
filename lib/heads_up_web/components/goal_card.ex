defmodule HeadsUpWeb.Components.GoalCard do
  use Phoenix.Component
  import HeadsUpWeb.CoreComponents, only: [icon: 1]
  alias HeadsUp.Accounts

  attr :goal, :map, required: true
  attr :show_category, :boolean, default: true
  attr :show_creator, :boolean, default: true
  attr :clickable, :boolean, default: true
  attr :click_event, :string, default: "view_goal"
  attr :current_user_id, :integer, default: nil
  attr :show_privacy_info, :boolean, default: true
  attr :can_view_details, :boolean, default: nil

  def goal_card(assigns) do
    # Determine if user can view goal details based on privacy
    can_view_details =
      if assigns[:can_view_details] != nil do
        assigns.can_view_details
      else
        case assigns.goal.privacy do
          :public ->
            true

          :private ->
            assigns.current_user_id && assigns.current_user_id == assigns.goal.user_id

          :friends ->
            assigns.current_user_id &&
              (assigns.current_user_id == assigns.goal.user_id ||
                 (assigns.current_user_id &&
                    Accounts.are_friends?(assigns.current_user_id, assigns.goal.user_id)))

          _ ->
            true
        end
      end

    # Can only click if can view details
    is_clickable = assigns.clickable && can_view_details

    assigns = assign(assigns, :can_view_details, can_view_details)
    assigns = assign(assigns, :is_clickable, is_clickable)

    ~H"""
    <div class={[
      "bg-white rounded-[40px] soft-shadow border border-slate-50 overflow-hidden transition-all duration-200",
      @is_clickable && "cursor-pointer hover:shadow-lg hover:scale-[1.01]"
    ]}>
      <%!-- Goal Image --%>
      <div
        class="w-full h-48 bg-slate-100"
        phx-click={if @is_clickable, do: @click_event, else: nil}
        phx-value-goal-id={@goal.id}
      >
        <%= if @can_view_details do %>
          <%= if @goal.image_path do %>
            <img src={@goal.image_path} alt={@goal.title} class="w-full h-full object-cover" />
          <% else %>
            <div class="w-full h-full bg-gradient-to-br from-blue-400 to-indigo-500 flex items-center justify-center">
              <.icon name="hero-flag" class="w-12 h-12 text-white/40" />
            </div>
          <% end %>
        <% else %>
          <div class="w-full h-full bg-gradient-to-br from-slate-300 to-slate-400 flex items-center justify-center">
            <div class="text-center text-white">
              <.icon name="hero-lock-closed" class="w-10 h-10 mx-auto mb-2 text-white/70" />
              <p class="text-sm font-bold">
                <%= case @goal.privacy do %>
                  <% :private -> %>
                    Private Goal
                  <% :friends -> %>
                    Friends Only
                  <% _ -> %>
                    Restricted
                <% end %>
              </p>
            </div>
          </div>
        <% end %>
      </div>

      <div class="p-8">
        <%!-- Goal Title --%>
        <h3
          class={[
            "text-xl font-extrabold text-slate-900 mb-3 line-clamp-2",
            @is_clickable && "cursor-pointer hover:text-blue-600 transition-colors"
          ]}
          phx-click={if @is_clickable, do: @click_event, else: nil}
          phx-value-goal-id={@goal.id}
        >
          <%= if @can_view_details do %>
            {@goal.title}
          <% else %>
            <span class="text-slate-400">Private Goal</span>
          <% end %>
        </h3>

        <%!-- Status & Privacy Badges (matching my-goals pattern) --%>
        <div class="flex flex-wrap items-center gap-2 mb-4">
          <HeadsUpWeb.Components.UI.StatusBadge.status_badge status={@goal.status} size={:sm} />
          <span class="bg-slate-100 text-slate-600 text-xs font-bold px-3 py-1.5 rounded-full inline-flex items-center gap-1">
            <.icon name={privacy_icon(@goal.privacy)} class="w-3 h-3" />
            {privacy_label(@goal.privacy)}
          </span>
          <%= if @show_category and @goal.group do %>
            <span class="bg-blue-50 text-blue-600 text-xs font-bold px-3 py-1.5 rounded-full">
              {@goal.group.name}
            </span>
          <% end %>
        </div>

        <%!-- Description --%>
        <%= if @can_view_details do %>
          <%= if @goal.description do %>
            <p class="text-slate-600 text-sm mb-6 line-clamp-2 leading-relaxed">
              {@goal.description}
            </p>
          <% end %>
        <% else %>
          <p class="text-slate-400 text-sm mb-6 italic">
            This goal's details are private
          </p>
        <% end %>

        <%= if @can_view_details do %>
          <%!-- Target Date --%>
          <%= if @goal.target_date do %>
            <div class="flex items-center text-sm text-slate-500 mb-4">
              <.icon name="hero-calendar" class="w-4 h-4 mr-2 text-slate-400" />
              <span class="font-medium">Target:</span>
              <span class="ml-2">{Calendar.strftime(@goal.target_date, "%B %d, %Y")}</span>
            </div>
          <% end %>

          <%!-- Progress Bar (using shared ProgressBar component) --%>
          <div class="mb-6">
            <HeadsUpWeb.Components.UI.ProgressBar.progress_bar
              value={@goal.progress || 0}
              max={100}
              size={:md}
              color={:indigo}
              show_label={true}
            />
          </div>

          <%!-- Creator --%>
          <%= if @show_creator and @goal.user do %>
            <div
              class="flex items-center text-sm text-slate-500 pb-4 mb-4 border-b border-slate-100 cursor-pointer hover:text-blue-600 transition-colors"
              phx-click="view_user"
              phx-value-user-id={@goal.user.id}
            >
              <.icon name="hero-user" class="w-4 h-4 mr-2" />
              <span class="font-medium">Created by:</span>
              <span class="ml-2 text-slate-900 font-bold">{@goal.user.name}</span>
            </div>
          <% end %>

          <%!-- Engagement Row (matching home/all-goals pattern) --%>
          <div class="flex items-center gap-6">
            <button
              phx-click="toggle_like"
              phx-value-goal-id={@goal.id}
              class="flex items-center gap-2 text-slate-500 hover:text-pink-500 transition-colors font-bold text-base"
            >
              <.icon name="hero-heart" class="w-5 h-5" /> {Map.get(@goal, :like_count, 0)}
            </button>
            <button
              phx-click="toggle_subscribe"
              phx-value-goal-id={@goal.id}
              class="flex items-center gap-2 text-slate-500 hover:text-blue-500 transition-colors font-bold text-base"
            >
              <.icon name="hero-eye" class="w-5 h-5" /> {Map.get(@goal, :subscriber_count, 0)}
            </button>
            <span class="flex items-center gap-2 text-slate-500 font-bold text-base">
              <.icon name="hero-share" class="w-5 h-5" /> Share
            </span>
          </div>
        <% else %>
          <%!-- Privacy Message --%>
          <div class="text-center py-4">
            <.icon name="hero-lock-closed" class="w-6 h-6 mx-auto mb-2 text-slate-300" />
            <p class="text-sm text-slate-400 font-medium">
              <%= case @goal.privacy do %>
                <% :private -> %>
                  This goal is private
                <% :friends -> %>
                  Friends only goal
                <% _ -> %>
                  Access restricted
              <% end %>
            </p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp privacy_icon(:public), do: "hero-globe-alt"
  defp privacy_icon(:friends), do: "hero-user-group"
  defp privacy_icon(_), do: "hero-lock-closed"

  defp privacy_label(:public), do: "Public"
  defp privacy_label(:friends), do: "Friends"
  defp privacy_label(_), do: "Private"
end
