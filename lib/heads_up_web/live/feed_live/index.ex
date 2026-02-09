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
    <style>
      @keyframes panelIn {
        from { opacity: 0; transform: translateY(15px); }
        to { opacity: 1; transform: translateY(0); }
      }
    </style>

    <div style="animation: panelIn 0.4s ease both;">
      <div class="max-w-4xl mx-auto px-5 sm:px-8 py-8 sm:py-12">
        <%!-- Panel Header --%>
        <div class="mb-8">
          <h1 class="font-['Bebas_Neue'] text-[clamp(2rem,4vw,2.6rem)] tracking-[3px] text-[#f0ece6] leading-none">
            Your Feed
          </h1>
          <p class="text-t66-text-muted text-[0.9rem] mt-1.5">
            Latest from your community
          </p>
        </div>

        <%!-- Feed Controls --%>
        <div class="flex items-center justify-between mb-6">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 bg-[rgba(255,77,0,0.15)] rounded-xl flex items-center justify-center">
              <.icon name="hero-bolt" class="w-5 h-5 text-t66-accent" />
            </div>
            <div>
              <p class="font-bold text-[#f0ece6] text-[0.9rem]">Recent Activity</p>
              <p class="text-sm text-t66-text-muted">{length(@feed_items)} items</p>
            </div>
          </div>
          <button
            phx-click="refresh"
            class="inline-flex items-center gap-2 bg-t66-card border border-white/[0.06] text-[#8a8680] px-5 py-2.5 rounded-xl font-bold text-sm hover:border-white/[0.12] hover:text-[#f0ece6] transition-colors"
          >
            <.icon name="hero-arrow-path" class="w-4 h-4" /> Refresh
          </button>
        </div>

        <%!-- Empty State --%>
        <%= if Enum.empty?(@feed_items) and not @loading do %>
          <div class="bg-t66-card border border-white/[0.06] rounded-2xl p-10 text-center">
            <div class="w-14 h-14 rounded-xl bg-[rgba(255,77,0,0.15)] flex items-center justify-center mx-auto mb-4">
              <.icon name="hero-rss" class="w-7 h-7 text-t66-accent" />
            </div>
            <div class="text-lg font-bold text-[#f0ece6] mb-2">No activities yet</div>
            <p class="text-sm text-t66-text-muted max-w-sm mx-auto">
              Follow some users or start challenges to see activities in your feed!
            </p>
            <.link
              navigate={~p"/people"}
              class="inline-flex items-center gap-2 mt-6 bg-t66-accent text-white px-6 py-3 rounded-xl font-bold text-sm hover:-translate-y-0.5 transition-transform shadow-[0_0_30px_rgba(255,77,0,0.2)]"
            >
              <.icon name="hero-users" class="w-4 h-4" /> Find People
            </.link>
          </div>
        <% else %>
          <%!-- Feed Items --%>
          <div class="flex flex-col gap-4">
            <%= for item <- @feed_items do %>
              <div class="bg-t66-card border border-white/[0.06] rounded-2xl p-6 hover:border-white/[0.1] transition-colors">
                <div class="flex items-start gap-3.5">
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
                        class="font-bold text-[#f0ece6] text-[0.88rem] hover:text-t66-accent transition-colors"
                      >
                        {item.user.name || item.user.user_name}
                      </.link>
                      <span class="text-t66-text-muted text-[0.72rem]">
                        {format_time_ago(item.inserted_at)}
                      </span>
                      <%= if item.xp_change > 0 do %>
                        <span class="bg-[rgba(34,197,94,0.12)] text-[#22c55e] text-xs font-bold px-3 py-1 rounded-full">
                          +{item.xp_change} XP
                        </span>
                      <% end %>
                      <%= if item.xp_change < 0 do %>
                        <span class="bg-[rgba(239,68,68,0.12)] text-[#ef4444] text-xs font-bold px-3 py-1 rounded-full">
                          {item.xp_change} XP
                        </span>
                      <% end %>
                    </div>

                    <%!-- Description --%>
                    <p class="text-[#8a8680] text-[0.9rem] leading-relaxed">
                      {item.user_friendly_description}
                    </p>

                    <%!-- Challenge Card --%>
                    <%= if item[:challenge] do %>
                      <.link
                        navigate={~p"/challenges/#{item.challenge.id}"}
                        class="block mt-4 p-4 bg-white/[0.03] border border-white/[0.06] rounded-xl hover:border-white/[0.12] transition-colors group"
                      >
                        <div class="flex items-center gap-3">
                          <div class="w-10 h-10 bg-[rgba(255,77,0,0.15)] rounded-xl flex items-center justify-center flex-shrink-0">
                            <.icon name="hero-bolt" class="w-5 h-5 text-t66-accent" />
                          </div>
                          <div class="min-w-0 flex-1">
                            <p class="font-bold text-[#f0ece6] text-sm group-hover:text-t66-accent transition-colors">
                              {item.challenge.title}
                            </p>
                            <%= if item.challenge.description do %>
                              <p class="text-t66-text-muted text-sm mt-0.5 truncate">
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
                            class="w-4 h-4 text-t66-text-muted flex-shrink-0"
                          />
                        </div>
                      </.link>
                    <% end %>

                    <%!-- Description Content --%>
                    <%= if item[:description] do %>
                      <div class="mt-4 p-4 bg-[rgba(255,77,0,0.06)] border-l-[3px] border-t66-accent rounded-xl">
                        <p class="text-[#8a8680] text-sm leading-relaxed">{item.description}</p>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
            <% end %>
          </div>

          <%!-- Load More --%>
          <%= if @has_more do %>
            <div class="text-center mt-10">
              <button
                phx-click="load_more"
                class="inline-flex items-center gap-2 bg-t66-card border border-white/[0.06] text-[#8a8680] px-8 py-3 rounded-xl font-bold text-sm hover:border-white/[0.12] hover:text-[#f0ece6] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
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
