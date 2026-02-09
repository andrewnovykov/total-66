defmodule HeadsUpWeb.FeedLive.Index do
  use HeadsUpWeb, :live_view
  alias HeadsUp.FeedService

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(HeadsUp.PubSub, "user_activities")
    end

    {:ok,
     socket
     |> assign(:page_title, "Feed")
     |> assign(:feed_items, [])
     |> assign(:loading, false)
     |> assign(:has_more, true)
     |> assign(:offset, 0)
     |> load_feed_items()}
  end

  def handle_event("load_more", _params, socket) do
    {:noreply, load_feed_items(socket)}
  end

  def handle_event("refresh", _params, socket) do
    {:noreply,
     socket
     |> assign(:feed_items, [])
     |> assign(:offset, 0)
     |> assign(:has_more, true)
     |> load_feed_items()}
  end

  def handle_info({:user_activity, _activity}, socket) do
    # Refresh feed when new activity occurs
    {:noreply,
     socket
     |> assign(:feed_items, [])
     |> assign(:offset, 0)
     |> load_feed_items()}
  end

  defp load_feed_items(socket) do
    current_user = socket.assigns.current_user
    limit = 20
    offset = socket.assigns.offset || 0

    new_items = FeedService.get_user_feed(current_user.id, limit: limit, offset: offset)
    existing_items = socket.assigns.feed_items || []

    socket
    |> assign(:feed_items, existing_items ++ new_items)
    |> assign(:offset, offset + limit)
    |> assign(:has_more, length(new_items) == limit)
    |> assign(:loading, false)
  end

  def render(assigns) do
    ~H"""
    <div class="flex gap-0 h-full">
      <%!-- ===== CENTER CONTENT ===== --%>
      <div class="flex-grow p-5 sm:p-8 lg:p-10 overflow-y-auto custom-scrollbar">
        <%!-- Hero Banner --%>
        <div class="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-[40px] p-8 sm:p-10 lg:p-12 mb-10 relative overflow-hidden text-white soft-shadow">
          <div class="relative z-10">
            <.link
              navigate={~p"/"}
              class="inline-flex items-center gap-2 text-blue-200 hover:text-white text-sm font-medium mb-6 transition-colors"
            >
              <.icon name="hero-arrow-left" class="w-4 h-4" /> Back to Home
            </.link>

            <span class="bg-blue-500/50 text-blue-100 text-xs font-bold px-4 py-1.5 rounded-full mb-4 inline-block uppercase tracking-wider">
              Activity
            </span>
            <h1 class="text-3xl sm:text-4xl lg:text-5xl font-extrabold mb-4 leading-tight">
              Your Feed
            </h1>
            <p class="text-blue-100 text-lg leading-relaxed max-w-xl">
              Stay up to date with activity from people you follow and your own progress.
            </p>
          </div>
          <div class="absolute right-0 top-0 h-full w-1/3 opacity-10 pointer-events-none flex items-center justify-center">
            <.icon name="hero-rss" class="w-48 h-48 lg:w-64 lg:h-64" />
          </div>
        </div>

        <%!-- Feed Controls --%>
        <div class="flex items-center justify-between mb-8">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center">
              <.icon name="hero-bolt" class="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <p class="font-extrabold text-slate-900">Recent Activity</p>
              <p class="text-sm text-slate-400">{length(@feed_items)} items</p>
            </div>
          </div>
          <button
            phx-click="refresh"
            class="inline-flex items-center gap-2 bg-white text-slate-600 px-5 py-2.5 rounded-xl font-bold text-sm soft-shadow hover:bg-slate-50 transition-colors"
          >
            <.icon name="hero-arrow-path" class="w-4 h-4" /> Refresh
          </button>
        </div>

        <%!-- Empty State --%>
        <%= if Enum.empty?(@feed_items) and not @loading do %>
          <HeadsUpWeb.Components.UI.EmptyState.empty_state
            icon="hero-rss"
            title="No activities yet"
            message="Follow some users or create goals to see activities in your feed!"
          >
            <:action>
              <.link
                navigate={~p"/people"}
                class="inline-flex items-center gap-2 bg-gradient-to-r from-blue-500 to-indigo-600 text-white text-sm font-bold px-6 py-3 rounded-xl transition-colors shadow-lg shadow-blue-500/20"
              >
                <.icon name="hero-users" class="w-4 h-4" /> Find People
              </.link>
            </:action>
          </HeadsUpWeb.Components.UI.EmptyState.empty_state>
        <% else %>
          <%!-- Feed Items --%>
          <div class="space-y-6">
            <%= for item <- @feed_items do %>
              <HeadsUpWeb.Components.UI.Card.card hover>
                <div class="flex items-start gap-4">
                  <%!-- Avatar --%>
                  <.link
                    navigate={~p"/people/#{item.user.user_name || item.user.id}"}
                    class="flex-shrink-0"
                  >
                    <HeadsUpWeb.Components.UI.Avatar.avatar
                      name={item.user.name || item.user.user_name || "U"}
                      src={item.user.image_path}
                      size={:lg}
                    />
                  </.link>

                  <div class="flex-1 min-w-0">
                    <%!-- Header Row --%>
                    <div class="flex flex-wrap items-center gap-2 mb-1">
                      <.link
                        navigate={~p"/people/#{item.user.user_name || item.user.id}"}
                        class="font-extrabold text-slate-900 text-base hover:text-blue-600 transition-colors"
                      >
                        {item.user.name || item.user.user_name}
                      </.link>
                      <span class="text-slate-400 text-sm font-medium">
                        {format_time_ago(item.inserted_at)}
                      </span>
                      <%= if item.xp_change > 0 do %>
                        <span class="bg-green-50 text-green-600 text-xs font-bold px-3 py-1 rounded-full">
                          +{item.xp_change} XP
                        </span>
                      <% end %>
                      <%= if item.xp_change < 0 do %>
                        <span class="bg-red-50 text-red-500 text-xs font-bold px-3 py-1 rounded-full">
                          {item.xp_change} XP
                        </span>
                      <% end %>
                    </div>

                    <%!-- Description --%>
                    <p class="text-slate-600 text-base leading-relaxed">
                      {item.user_friendly_description}
                    </p>

                    <%!-- Challenge Card --%>
                    <%= if item[:challenge] do %>
                      <.link
                        navigate={~p"/challenges/#{item.challenge.id}"}
                        class="block mt-4 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors group"
                      >
                        <div class="flex items-center gap-3">
                          <div class="w-10 h-10 bg-amber-50 rounded-xl flex items-center justify-center flex-shrink-0">
                            <.icon name="hero-bolt" class="w-5 h-5 text-amber-600" />
                          </div>
                          <div class="min-w-0 flex-1">
                            <p class="font-bold text-slate-900 text-sm group-hover:text-blue-600 transition-colors">
                              {item.challenge.title}
                            </p>
                            <%= if item.challenge.description do %>
                              <p class="text-slate-400 text-sm mt-0.5 truncate">
                                {String.slice(item.challenge.description, 0, 100)}{if String.length(
                                                                                        item.challenge.description ||
                                                                                          ""
                                                                                      ) > 100,
                                                                                      do: "...",
                                                                                      else: ""}
                              </p>
                            <% end %>
                          </div>
                          <.icon
                            name="hero-chevron-right"
                            class="w-4 h-4 text-slate-400 flex-shrink-0"
                          />
                        </div>
                      </.link>
                    <% end %>

                    <%!-- Description Content --%>
                    <%= if item[:description] do %>
                      <div class="mt-4 p-4 bg-blue-50 rounded-2xl border-l-4 border-blue-400">
                        <p class="text-slate-700 text-sm leading-relaxed">{item.description}</p>
                      </div>
                    <% end %>
                  </div>
                </div>
              </HeadsUpWeb.Components.UI.Card.card>
            <% end %>
          </div>

          <%!-- Load More --%>
          <%= if @has_more do %>
            <div class="text-center mt-10">
              <button
                phx-click="load_more"
                class="inline-flex items-center gap-2 bg-white text-slate-600 px-8 py-3 rounded-xl font-bold text-sm soft-shadow hover:bg-slate-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                disabled={@loading}
              >
                <%= if @loading do %>
                  <.icon name="hero-arrow-path" class="w-4 h-4 animate-spin" /> Loading...
                <% else %>
                  <.icon name="hero-arrow-down" class="w-4 h-4" /> Load More
                <% end %>
              </button>
            </div>
          <% end %>
        <% end %>
      </div>

      <%!-- ===== RIGHT SIDEBAR ===== --%>
      <aside class="hidden xl:flex flex-col w-[420px] flex-shrink-0 bg-white border-l border-slate-100 p-8 overflow-y-auto custom-scrollbar gap-10">
        <%!-- Feed Stats --%>
        <div>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Feed Stats</h3>
          <div class="space-y-4">
            <div class="flex items-center gap-4 p-5 bg-slate-50 rounded-2xl">
              <div class="w-14 h-14 bg-blue-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-bolt" class="w-7 h-7 text-blue-600" />
              </div>
              <div>
                <p class="text-3xl font-extrabold text-slate-900">{length(@feed_items)}</p>
                <p class="text-xs text-slate-400 font-medium">Activities Loaded</p>
              </div>
            </div>
          </div>
        </div>

        <%!-- Quick Links --%>
        <div>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Quick Links</h3>
          <div class="space-y-3">
            <.link
              navigate={~p"/people"}
              class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors group"
            >
              <div class="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-users" class="w-5 h-5 text-blue-600" />
              </div>
              <span class="font-bold text-slate-700 group-hover:text-slate-900">Find People</span>
              <.icon name="hero-chevron-right" class="w-5 h-5 text-slate-400 ml-auto" />
            </.link>
            <.link
              navigate={~p"/my-challenges"}
              class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors group"
            >
              <div class="w-10 h-10 bg-indigo-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-bolt" class="w-5 h-5 text-indigo-600" />
              </div>
              <span class="font-bold text-slate-700 group-hover:text-slate-900">My Challenges</span>
              <.icon name="hero-chevron-right" class="w-5 h-5 text-slate-400 ml-auto" />
            </.link>
            <.link
              navigate={~p"/connections"}
              class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors group"
            >
              <div class="w-10 h-10 bg-green-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-user-group" class="w-5 h-5 text-green-600" />
              </div>
              <span class="font-bold text-slate-700 group-hover:text-slate-900">Connections</span>
              <.icon name="hero-chevron-right" class="w-5 h-5 text-slate-400 ml-auto" />
            </.link>
            <.link
              navigate={~p"/challenges"}
              class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors group"
            >
              <div class="w-10 h-10 bg-amber-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-fire" class="w-5 h-5 text-amber-600" />
              </div>
              <span class="font-bold text-slate-700 group-hover:text-slate-900">Browse Challenges</span>
              <.icon name="hero-chevron-right" class="w-5 h-5 text-slate-400 ml-auto" />
            </.link>
          </div>
        </div>

        <%!-- Tips --%>
        <div>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Grow Your Feed</h3>
          <div class="space-y-4">
            <div class="flex items-start gap-4 p-4 bg-slate-50 rounded-2xl">
              <div class="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center flex-shrink-0">
                <.icon name="hero-user-plus" class="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <p class="font-bold text-slate-900 text-sm">Follow People</p>
                <p class="text-slate-500 text-sm mt-1">
                  Follow users to see their goal updates in your feed.
                </p>
              </div>
            </div>
            <div class="flex items-start gap-4 p-4 bg-slate-50 rounded-2xl">
              <div class="w-10 h-10 bg-indigo-50 rounded-xl flex items-center justify-center flex-shrink-0">
                <.icon name="hero-pencil-square" class="w-5 h-5 text-indigo-600" />
              </div>
              <div>
                <p class="font-bold text-slate-900 text-sm">Stay Active</p>
                <p class="text-slate-500 text-sm mt-1">
                  Create goals and post updates to earn XP and engage your followers.
                </p>
              </div>
            </div>
          </div>
        </div>
      </aside>
    </div>
    """
  end

  defp format_time_ago(datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "#{diff}s ago"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      true -> "#{div(diff, 86400)}d ago"
    end
  end
end
