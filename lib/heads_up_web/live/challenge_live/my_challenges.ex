defmodule HeadsUpWeb.ChallengeLive.MyChallenges do
  use HeadsUpWeb, :live_view
  alias HeadsUp.Challenges

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    my_challenges = Challenges.list_my_challenges(current_user.id)
    categories = Challenges.list_active_categories()

    socket =
      socket
      |> assign(:my_challenges, my_challenges)
      |> assign(:filtered_challenges, my_challenges)
      |> assign(:categories, categories)
      |> assign(:filter_status, "all")
      |> assign(:search_query, "")
      |> assign(:page_title, "My Challenges")

    {:ok, socket}
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    filtered =
      filter_challenges(socket.assigns.my_challenges, status, socket.assigns.search_query)

    {:noreply,
     socket
     |> assign(:filtered_challenges, filtered)
     |> assign(:filter_status, status)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    filtered =
      filter_challenges(socket.assigns.my_challenges, socket.assigns.filter_status, query)

    {:noreply,
     socket
     |> assign(:filtered_challenges, filtered)
     |> assign(:search_query, query)}
  end

  defp filter_challenges(challenges, status, query) do
    challenges
    |> filter_by_status(status)
    |> filter_by_search(query)
  end

  defp filter_by_status(challenges, "all"), do: challenges

  defp filter_by_status(challenges, status) do
    status_atom = String.to_existing_atom(status)
    Enum.filter(challenges, &(&1.status == status_atom))
  end

  defp filter_by_search(challenges, ""), do: challenges

  defp filter_by_search(challenges, query) do
    query = String.downcase(query)

    Enum.filter(challenges, fn c ->
      String.contains?(String.downcase(c.title), query) ||
        (c.description && String.contains?(String.downcase(c.description), query))
    end)
  end

  defp challenge_counts(challenges) do
    %{
      all: length(challenges),
      active: Enum.count(challenges, &(&1.status == :active)),
      completed: Enum.count(challenges, &(&1.status == :completed)),
      failed: Enum.count(challenges, &(&1.status == :failed)),
      cancelled: Enum.count(challenges, &(&1.status == :cancelled))
    }
  end

  defp days_remaining(challenge) do
    if challenge.end_date do
      remaining = Date.diff(challenge.end_date, Date.utc_today())
      max(remaining, 0)
    else
      nil
    end
  end

  defp days_total(challenge) do
    if challenge.start_date && challenge.end_date do
      Date.diff(challenge.end_date, challenge.start_date)
    else
      nil
    end
  end

  defp days_elapsed(challenge) do
    if challenge.start_date do
      elapsed = Date.diff(Date.utc_today(), challenge.start_date)
      max(elapsed, 0)
    else
      nil
    end
  end

  defp progress_percentage(challenge) do
    total = days_total(challenge)
    elapsed = days_elapsed(challenge)

    if total && total > 0 && elapsed do
      min(round(elapsed / total * 100), 100)
    else
      0
    end
  end

  @impl true
  def render(assigns) do
    counts = challenge_counts(assigns.my_challenges)
    assigns = assign(assigns, :counts, counts)

    ~H"""
    <div class="flex gap-0 h-full">
      <%!-- ===== CENTER CONTENT ===== --%>
      <div class="flex-grow p-5 sm:p-8 lg:p-10 overflow-y-auto custom-scrollbar">
        <%!-- Hero Banner --%>
        <div class="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-[40px] p-8 sm:p-10 lg:p-12 mb-10 relative overflow-hidden text-white soft-shadow">
          <div class="relative z-10">
            <span class="bg-blue-500/50 text-blue-100 text-xs font-bold px-4 py-1.5 rounded-full mb-4 inline-block uppercase tracking-wider">
              Dashboard
            </span>
            <h1 class="text-3xl sm:text-4xl lg:text-5xl font-extrabold mb-4 leading-tight">
              My Challenges
            </h1>
            <p class="text-blue-100 text-lg leading-relaxed max-w-xl mb-8">
              <%= cond do %>
                <% @counts.active > 0 -> %>
                  You have {@counts.active} active challenge{if @counts.active != 1, do: "s"}. Keep going!
                <% @counts.all > 0 -> %>
                  You have {@counts.all} challenge{if @counts.all != 1, do: "s"}. Start a new one!
                <% true -> %>
                  Track your personal challenge progress and push your limits.
              <% end %>
            </p>

            <div class="flex flex-col sm:flex-row gap-3">
              <.link
                navigate={~p"/challenges"}
                class="inline-flex items-center justify-center gap-2 bg-white text-blue-600 px-8 py-4 rounded-2xl font-bold text-base hover:scale-105 transition-all duration-200 soft-shadow"
              >
                <.icon name="hero-magnifying-glass" class="w-5 h-5" /> Browse Templates
              </.link>
              <.link
                navigate={~p"/challenges/new"}
                class="inline-flex items-center justify-center gap-2 bg-white/15 backdrop-blur-sm text-white border border-white/20 px-8 py-4 rounded-2xl font-bold text-base hover:bg-white/25 transition-all duration-200"
              >
                <.icon name="hero-plus" class="w-5 h-5" /> Create Challenge
              </.link>
            </div>
          </div>
          <div class="absolute right-0 top-0 h-full w-1/3 opacity-10 pointer-events-none flex items-center justify-center">
            <.icon name="hero-bolt" class="w-48 h-48 lg:w-64 lg:h-64" />
          </div>
        </div>

        <%!-- Filter Row --%>
        <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-8">
          <div class="flex items-center gap-3">
            <h2 class="text-2xl font-extrabold text-slate-900">
              {case @filter_status do
                "active" -> "Active Challenges"
                "completed" -> "Completed Challenges"
                "failed" -> "Failed Challenges"
                "cancelled" -> "Cancelled Challenges"
                _ -> "All Challenges"
              end}
            </h2>
            <span class="text-slate-400 text-sm font-medium">
              {length(@filtered_challenges)} challenges
            </span>
          </div>

          <div class="flex items-center gap-3 flex-wrap">
            <%!-- Status Filter Pills --%>
            <div class="flex gap-2">
              <button
                phx-click="filter_status"
                phx-value-status="all"
                class={[
                  "px-5 py-2.5 rounded-xl text-sm font-bold transition-all",
                  if(@filter_status == "all",
                    do: "bg-slate-900 text-white",
                    else: "bg-white text-slate-500 soft-shadow hover:bg-slate-50"
                  )
                ]}
              >
                All ({@counts.all})
              </button>
              <button
                phx-click="filter_status"
                phx-value-status="active"
                class={[
                  "px-5 py-2.5 rounded-xl text-sm font-bold transition-all",
                  if(@filter_status == "active",
                    do: "bg-slate-900 text-white",
                    else: "bg-white text-slate-500 soft-shadow hover:bg-slate-50"
                  )
                ]}
              >
                Active ({@counts.active})
              </button>
              <button
                phx-click="filter_status"
                phx-value-status="completed"
                class={[
                  "px-5 py-2.5 rounded-xl text-sm font-bold transition-all hidden sm:block",
                  if(@filter_status == "completed",
                    do: "bg-slate-900 text-white",
                    else: "bg-white text-slate-500 soft-shadow hover:bg-slate-50"
                  )
                ]}
              >
                Completed ({@counts.completed})
              </button>
              <button
                phx-click="filter_status"
                phx-value-status="failed"
                class={[
                  "px-5 py-2.5 rounded-xl text-sm font-bold transition-all hidden sm:block",
                  if(@filter_status == "failed",
                    do: "bg-slate-900 text-white",
                    else: "bg-white text-slate-500 soft-shadow hover:bg-slate-50"
                  )
                ]}
              >
                Failed ({@counts.failed})
              </button>
            </div>
          </div>
        </div>

        <%!-- Challenges Feed --%>
        <div class="space-y-6">
          <%= for challenge <- @filtered_challenges do %>
            <.challenge_card challenge={challenge} />
          <% end %>
        </div>

        <%!-- Empty State --%>
        <%= if @filtered_challenges == [] do %>
          <HeadsUpWeb.Components.UI.Card.card padding={:lg} class="text-center">
            <div class="py-8">
              <div class="w-16 h-16 mx-auto bg-slate-100 rounded-2xl flex items-center justify-center mb-4">
                <.icon name="hero-bolt" class="w-8 h-8 text-slate-400" />
              </div>
              <%= if @filter_status == "all" && @search_query == "" do %>
                <h3 class="text-xl font-extrabold text-slate-900 mb-2">No challenges yet</h3>
                <p class="text-slate-500 mb-6">Browse templates and start your first challenge!</p>
                <.link
                  navigate={~p"/challenges"}
                  class="inline-flex items-center gap-2 bg-gradient-to-r from-blue-500 to-indigo-600 text-white px-6 py-3 rounded-2xl font-bold hover:scale-105 transition-all"
                >
                  <.icon name="hero-magnifying-glass" class="w-4 h-4" /> Browse Templates
                </.link>
              <% else %>
                <h3 class="text-xl font-extrabold text-slate-900 mb-2">
                  No {if @filter_status != "all", do: @filter_status <> " ", else: ""}challenges found
                </h3>
                <p class="text-slate-500 mb-6">Try adjusting your filters or search query.</p>
                <button
                  phx-click="filter_status"
                  phx-value-status="all"
                  class="inline-flex items-center gap-2 bg-gradient-to-r from-blue-500 to-indigo-600 text-white px-6 py-3 rounded-2xl font-bold hover:scale-105 transition-all"
                >
                  Show All Challenges
                </button>
              <% end %>
            </div>
          </HeadsUpWeb.Components.UI.Card.card>
        <% end %>
      </div>

      <%!-- ===== RIGHT SIDEBAR ===== --%>
      <aside class="hidden xl:flex flex-col w-[420px] flex-shrink-0 bg-white border-l border-slate-100 p-8 overflow-y-auto custom-scrollbar gap-10">
        <%!-- Search --%>
        <div>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Search</h3>
          <div class="relative">
            <.icon
              name="hero-magnifying-glass"
              class="w-5 h-5 absolute left-4 top-1/2 -translate-y-1/2 text-slate-400"
            />
            <input
              type="text"
              phx-keyup="search"
              phx-debounce="300"
              name="query"
              value={@search_query}
              placeholder="Search my challenges..."
              class="w-full pl-12 pr-5 py-4 bg-slate-50 border-0 rounded-2xl text-slate-800 text-sm focus:ring-2 focus:ring-blue-500/30 transition"
            />
          </div>
        </div>

        <%!-- Overview Stats --%>
        <div>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Overview</h3>
          <div class="space-y-4">
            <div class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl">
              <div class="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-bolt" class="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <p class="text-2xl font-extrabold text-slate-900">{@counts.all}</p>
                <p class="text-slate-500 text-xs font-bold">Total Challenges</p>
              </div>
            </div>
            <div class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl">
              <div class="w-10 h-10 bg-green-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-play" class="w-5 h-5 text-green-600" />
              </div>
              <div>
                <p class="text-2xl font-extrabold text-slate-900">{@counts.active}</p>
                <p class="text-slate-500 text-xs font-bold">Active</p>
              </div>
            </div>
            <div class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl">
              <div class="w-10 h-10 bg-indigo-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-trophy" class="w-5 h-5 text-indigo-600" />
              </div>
              <div>
                <p class="text-2xl font-extrabold text-slate-900">{@counts.completed}</p>
                <p class="text-slate-500 text-xs font-bold">Completed</p>
              </div>
            </div>
          </div>
        </div>

        <%!-- Quick Links --%>
        <div>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Quick Links</h3>
          <div class="space-y-3">
            <.link
              navigate={~p"/challenges"}
              class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors group"
            >
              <div class="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-bolt" class="w-5 h-5 text-blue-600" />
              </div>
              <span class="font-bold text-slate-700 group-hover:text-slate-900">
                Browse Templates
              </span>
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
          </div>
        </div>

        <%!-- Start New Challenge Promo --%>
        <div class="bg-gradient-to-br from-blue-600 to-indigo-700 rounded-[32px] p-8 text-white">
          <div class="w-14 h-14 bg-white/20 rounded-2xl flex items-center justify-center mb-4">
            <.icon name="hero-rocket-launch" class="w-7 h-7 text-white" />
          </div>
          <h4 class="text-xl font-extrabold mb-2">Ready for more?</h4>
          <p class="text-blue-100 text-sm mb-6">
            Browse templates or create your own challenge to push your limits.
          </p>
          <.link
            navigate={~p"/challenges"}
            class="inline-flex items-center gap-2 bg-white text-blue-600 px-6 py-3 rounded-2xl font-bold text-sm hover:scale-105 transition-all"
          >
            <.icon name="hero-magnifying-glass" class="w-4 h-4" /> Browse Templates
          </.link>
        </div>
      </aside>
    </div>
    """
  end

  defp challenge_card(assigns) do
    progress = progress_percentage(assigns.challenge)
    remaining = days_remaining(assigns.challenge)
    total = days_total(assigns.challenge)

    assigns =
      assigns
      |> assign(:progress, progress)
      |> assign(:remaining, remaining)
      |> assign(:total, total)

    ~H"""
    <.link navigate={~p"/challenges/#{@challenge.id}"} class="block cursor-pointer group">
      <HeadsUpWeb.Components.UI.Card.card hover padding={:md}>
        <div class="flex flex-col sm:flex-row gap-6">
          <%!-- Challenge Image/Gradient --%>
          <div class={[
            "w-full sm:w-40 h-40 sm:h-32 rounded-2xl flex items-center justify-center flex-shrink-0",
            case @challenge.status do
              :active -> "bg-gradient-to-br from-blue-500 to-indigo-600"
              :completed -> "bg-gradient-to-br from-green-500 to-emerald-600"
              :failed -> "bg-gradient-to-br from-slate-400 to-slate-500"
              :cancelled -> "bg-gradient-to-br from-slate-300 to-slate-400"
              _ -> "bg-gradient-to-br from-blue-500 to-indigo-600"
            end
          ]}>
            <.icon name={status_icon(@challenge.status)} class="w-12 h-12 text-white/80" />
          </div>

          <%!-- Content --%>
          <div class="flex-1 min-w-0">
            <%!-- Badges --%>
            <div class="flex flex-wrap items-center gap-2 mb-2">
              <HeadsUpWeb.Components.UI.StatusBadge.status_badge
                status={@challenge.status}
                size={:sm}
              />
              <span class={[
                "px-3 py-1 text-xs font-bold rounded-full",
                if(@challenge.type == :predefined,
                  do: "bg-purple-50 text-purple-600",
                  else: "bg-blue-50 text-blue-600"
                )
              ]}>
                {if @challenge.type == :predefined, do: "Official", else: "Community"}
              </span>
              <%= if @challenge.category do %>
                <span class="px-3 py-1 text-xs font-bold rounded-full bg-slate-100 text-slate-600">
                  {@challenge.category.name}
                </span>
              <% end %>
            </div>

            <%!-- Title --%>
            <h3 class="text-lg font-extrabold text-slate-900 mb-1 line-clamp-1 group-hover:text-blue-600 transition-colors">
              {@challenge.title}
            </h3>

            <%!-- Description --%>
            <%= if @challenge.description do %>
              <p class="text-slate-500 text-sm mb-3 line-clamp-2">{@challenge.description}</p>
            <% end %>

            <%!-- Progress Bar (for active challenges) --%>
            <%= if @challenge.status == :active && @total && @total > 0 do %>
              <div class="mb-3">
                <div class="flex justify-between text-xs mb-1.5">
                  <span class="font-bold text-slate-500">Progress</span>
                  <span class="font-extrabold text-indigo-600">{@progress}%</span>
                </div>
                <div class="w-full bg-slate-100 rounded-full h-2.5 overflow-hidden">
                  <div
                    class="h-2.5 rounded-full bg-indigo-500 transition-all duration-500"
                    style={"width: #{@progress}%"}
                  />
                </div>
              </div>
            <% end %>

            <%!-- Meta --%>
            <div class="flex flex-wrap items-center gap-4 text-sm text-slate-400">
              <%= if @challenge.start_date && @challenge.end_date do %>
                <span class="flex items-center gap-1.5">
                  <.icon name="hero-calendar" class="w-4 h-4" />
                  {Calendar.strftime(@challenge.start_date, "%b %d")} - {Calendar.strftime(
                    @challenge.end_date,
                    "%b %d"
                  )}
                </span>
              <% end %>
              <%= if @challenge.status == :active && @remaining do %>
                <span class="flex items-center gap-1.5">
                  <.icon name="hero-clock" class="w-4 h-4" />
                  {@remaining} days left
                </span>
              <% end %>
              <%= if @total do %>
                <span class="flex items-center gap-1.5 hidden sm:flex">
                  <.icon name="hero-arrow-path" class="w-4 h-4" />
                  {@total} day challenge
                </span>
              <% end %>
            </div>
          </div>
        </div>
      </HeadsUpWeb.Components.UI.Card.card>
    </.link>
    """
  end

  defp status_icon(:active), do: "hero-bolt"
  defp status_icon(:completed), do: "hero-trophy"
  defp status_icon(:failed), do: "hero-x-circle"
  defp status_icon(:cancelled), do: "hero-x-mark"
  defp status_icon(_), do: "hero-bolt"
end
