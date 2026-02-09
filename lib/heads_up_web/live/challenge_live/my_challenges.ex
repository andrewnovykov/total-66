defmodule HeadsUpWeb.ChallengeLive.MyChallenges do
  use HeadsUpWeb, :live_view
  alias HeadsUp.Challenges

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    my_challenges = Challenges.list_my_challenges(current_user.id)

    socket =
      socket
      |> assign(:my_challenges, my_challenges)
      |> assign(:filtered_challenges, my_challenges)
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
    <style>
      @keyframes panelIn {
        from { opacity: 0; transform: translateY(15px); }
        to { opacity: 1; transform: translateY(0); }
      }
    </style>

    <div style="animation: panelIn 0.4s ease both;">
      <div class="max-w-4xl mx-auto px-5 sm:px-8 py-8 sm:py-12">
        <%!-- Panel Header --%>
        <div class="flex flex-col sm:flex-row sm:items-end justify-between gap-4 mb-8">
          <div>
            <h1 class="font-['Bebas_Neue'] text-[clamp(2rem,4vw,2.6rem)] tracking-[3px] text-[#f0ece6] leading-none">
              My Challenges
            </h1>
            <p class="text-t66-text-muted text-[0.9rem] mt-1.5">
              Your history of grit and growth
            </p>
          </div>
          <div class="flex gap-2.5">
            <.link
              navigate={~p"/challenges"}
              class="inline-flex items-center gap-2 bg-t66-card border border-white/[0.06] text-[#8a8680] px-5 py-2.5 rounded-xl font-bold text-sm hover:border-white/[0.12] hover:text-[#f0ece6] transition-colors"
            >
              <.icon name="hero-magnifying-glass" class="w-4 h-4" /> Browse Templates
            </.link>
            <.link
              navigate={~p"/challenges/new"}
              class="inline-flex items-center gap-2 bg-t66-accent text-white px-5 py-2.5 rounded-xl font-bold text-sm hover:-translate-y-0.5 transition-all shadow-[0_0_30px_rgba(255,77,0,0.2)]"
            >
              <.icon name="hero-plus" class="w-4 h-4" /> Create Challenge
            </.link>
          </div>
        </div>

        <%!-- Stats Row --%>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-3 mb-8">
          <div class="bg-t66-card border border-white/[0.06] rounded-2xl p-5 text-center">
            <div class="font-['Bebas_Neue'] text-[2rem] leading-none text-t66-accent">{@counts.all}</div>
            <div class="text-[0.6rem] uppercase tracking-[2px] text-t66-text-muted mt-1">Total</div>
          </div>
          <div class="bg-t66-card border border-white/[0.06] rounded-2xl p-5 text-center">
            <div class="font-['Bebas_Neue'] text-[2rem] leading-none text-t66-accent">{@counts.active}</div>
            <div class="text-[0.6rem] uppercase tracking-[2px] text-t66-text-muted mt-1">Active</div>
          </div>
          <div class="bg-t66-card border border-white/[0.06] rounded-2xl p-5 text-center">
            <div class="font-['Bebas_Neue'] text-[2rem] leading-none text-[#22c55e]">{@counts.completed}</div>
            <div class="text-[0.6rem] uppercase tracking-[2px] text-t66-text-muted mt-1">Completed</div>
          </div>
          <div class="bg-t66-card border border-white/[0.06] rounded-2xl p-5 text-center">
            <div class="font-['Bebas_Neue'] text-[2rem] leading-none text-[#ef4444]">{@counts.failed}</div>
            <div class="text-[0.6rem] uppercase tracking-[2px] text-t66-text-muted mt-1">Failed</div>
          </div>
        </div>

        <%!-- Search + Filter Row --%>
        <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
          <%!-- Filter Pills --%>
          <div class="flex flex-wrap gap-1.5">
            <button
              phx-click="filter_status"
              phx-value-status="all"
              class={[
                "px-[18px] py-2 rounded-lg text-[0.78rem] font-semibold tracking-[0.5px] transition-all border",
                if(@filter_status == "all",
                  do: "border-[#ff4d00] text-[#ff4d00] bg-[rgba(255,77,0,0.15)]",
                  else: "border-white/[0.06] text-[#5a5754] hover:border-white/[0.12] hover:text-[#8a8680]"
                )
              ]}
            >
              All ({@counts.all})
            </button>
            <button
              phx-click="filter_status"
              phx-value-status="active"
              class={[
                "px-[18px] py-2 rounded-lg text-[0.78rem] font-semibold tracking-[0.5px] transition-all border",
                if(@filter_status == "active",
                  do: "border-[#ff4d00] text-[#ff4d00] bg-[rgba(255,77,0,0.15)]",
                  else: "border-white/[0.06] text-[#5a5754] hover:border-white/[0.12] hover:text-[#8a8680]"
                )
              ]}
            >
              Active ({@counts.active})
            </button>
            <button
              phx-click="filter_status"
              phx-value-status="completed"
              class={[
                "px-[18px] py-2 rounded-lg text-[0.78rem] font-semibold tracking-[0.5px] transition-all border",
                if(@filter_status == "completed",
                  do: "border-[#ff4d00] text-[#ff4d00] bg-[rgba(255,77,0,0.15)]",
                  else: "border-white/[0.06] text-[#5a5754] hover:border-white/[0.12] hover:text-[#8a8680]"
                )
              ]}
            >
              Completed ({@counts.completed})
            </button>
            <button
              phx-click="filter_status"
              phx-value-status="failed"
              class={[
                "px-[18px] py-2 rounded-lg text-[0.78rem] font-semibold tracking-[0.5px] transition-all border",
                if(@filter_status == "failed",
                  do: "border-[#ff4d00] text-[#ff4d00] bg-[rgba(255,77,0,0.15)]",
                  else: "border-white/[0.06] text-[#5a5754] hover:border-white/[0.12] hover:text-[#8a8680]"
                )
              ]}
            >
              Failed ({@counts.failed})
            </button>
          </div>

          <%!-- Search --%>
          <div class="relative w-full sm:w-auto">
            <.icon
              name="hero-magnifying-glass"
              class="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-t66-text-muted"
            />
            <input
              type="text"
              phx-keyup="search"
              phx-debounce="300"
              name="query"
              value={@search_query}
              placeholder="Search challenges..."
              class="w-full sm:w-[220px] pl-10 pr-4 py-2 bg-t66-card border border-white/[0.06] rounded-lg text-[#f0ece6] text-[0.85rem] outline-none transition-all placeholder:text-t66-text-muted focus:border-[rgba(255,77,0,0.4)] focus:ring-[3px] focus:ring-[rgba(255,77,0,0.08)]"
            />
          </div>
        </div>

        <%!-- Challenges List --%>
        <div class="flex flex-col gap-3">
          <%= for challenge <- @filtered_challenges do %>
            <.challenge_card challenge={challenge} />
          <% end %>
        </div>

        <%!-- Empty State --%>
        <%= if @filtered_challenges == [] do %>
          <div class="bg-t66-card border border-white/[0.06] rounded-2xl p-10 text-center">
            <div class="w-14 h-14 rounded-xl bg-[rgba(255,77,0,0.15)] flex items-center justify-center mx-auto mb-4">
              <.icon name="hero-bolt" class="w-7 h-7 text-t66-accent" />
            </div>
            <%= if @filter_status == "all" && @search_query == "" do %>
              <div class="text-lg font-bold text-[#f0ece6] mb-2">No challenges yet</div>
              <p class="text-sm text-t66-text-muted max-w-sm mx-auto mb-6">
                Browse templates and start your first challenge!
              </p>
              <.link
                navigate={~p"/challenges"}
                class="inline-flex items-center gap-2 bg-t66-accent text-white px-6 py-3 rounded-xl font-bold text-sm hover:-translate-y-0.5 transition-transform shadow-[0_0_30px_rgba(255,77,0,0.2)]"
              >
                <.icon name="hero-magnifying-glass" class="w-4 h-4" /> Browse Templates
              </.link>
            <% else %>
              <div class="text-lg font-bold text-[#f0ece6] mb-2">
                No {if @filter_status != "all", do: @filter_status <> " ", else: ""}challenges found
              </div>
              <p class="text-sm text-t66-text-muted max-w-sm mx-auto mb-6">
                Try adjusting your filters or search query.
              </p>
              <button
                phx-click="filter_status"
                phx-value-status="all"
                class="inline-flex items-center gap-2 bg-t66-accent text-white px-6 py-3 rounded-xl font-bold text-sm hover:-translate-y-0.5 transition-transform shadow-[0_0_30px_rgba(255,77,0,0.2)]"
              >
                Show All Challenges
              </button>
            <% end %>
          </div>
        <% end %>

        <%!-- Start New Challenge Button --%>
        <%= if @counts.all > 0 do %>
          <div class="mt-8 flex flex-col sm:flex-row gap-3">
            <.link
              navigate={~p"/challenges"}
              class="inline-flex items-center justify-center gap-2 bg-t66-accent text-white px-7 py-3.5 rounded-xl font-bold text-[0.8rem] tracking-[1.5px] uppercase hover:-translate-y-0.5 transition-all shadow-[0_0_30px_rgba(255,77,0,0.2)] hover:shadow-[0_0_50px_rgba(255,77,0,0.35)]"
            >
              <.icon name="hero-fire" class="w-4 h-4" /> Start New Challenge
            </.link>
            <.link
              navigate={~p"/challenges/new"}
              class="inline-flex items-center justify-center gap-2 bg-t66-card border border-white/[0.06] text-[#8a8680] px-7 py-3.5 rounded-xl font-bold text-[0.8rem] tracking-[1.5px] uppercase hover:border-white/[0.12] hover:text-[#f0ece6] transition-colors"
            >
              <.icon name="hero-plus" class="w-4 h-4" /> Create Custom
            </.link>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp challenge_card(assigns) do
    progress = progress_percentage(assigns.challenge)
    remaining = days_remaining(assigns.challenge)
    total = days_total(assigns.challenge)
    elapsed = days_elapsed(assigns.challenge)
    circumference = 2 * :math.pi() * 20

    assigns =
      assigns
      |> assign(:progress, progress)
      |> assign(:remaining, remaining)
      |> assign(:total, total)
      |> assign(:elapsed, elapsed)
      |> assign(:circumference, circumference)
      |> assign(:stroke_offset, circumference - progress / 100 * circumference)

    ~H"""
    <.link navigate={~p"/my-challenges/#{@challenge.id}"} class="block group">
      <div class="bg-t66-card border border-white/[0.06] rounded-2xl p-5 sm:p-6 hover:border-white/[0.1] transition-colors">
        <div class="flex items-center gap-4 sm:gap-5">
          <%!-- Challenge Icon --%>
          <div class={[
            "w-[46px] h-[46px] rounded-xl flex items-center justify-center flex-shrink-0",
            if(@challenge.type == :official,
              do: "bg-[rgba(255,77,0,0.15)]",
              else: "bg-[rgba(0,212,170,0.12)]"
            )
          ]}>
            <.icon
              name={if @challenge.type == :official, do: "hero-fire", else: "hero-bolt"}
              class={if @challenge.type == :official, do: "w-6 h-6 text-t66-accent", else: "w-6 h-6 text-t66-cyan"}
            />
          </div>

          <%!-- Challenge Info --%>
          <div class="flex-1 min-w-0">
            <div class="flex flex-wrap items-center gap-2">
              <span class="font-bold text-[0.9rem] text-[#f0ece6] group-hover:text-t66-accent transition-colors truncate">
                {@challenge.title}
              </span>
              <span class={[
                "text-[0.55rem] uppercase tracking-[1.5px] px-[7px] py-[2px] rounded font-bold",
                if(@challenge.type == :official,
                  do: "text-t66-accent bg-[rgba(255,77,0,0.15)]",
                  else: "text-t66-cyan bg-[rgba(0,212,170,0.12)]"
                )
              ]}>
                {if @challenge.type == :official, do: "Official", else: "Community"}
              </span>
            </div>
            <div class="text-t66-text-muted text-[0.78rem] mt-0.5">
              <%= if @challenge.start_date && @challenge.end_date do %>
                {Calendar.strftime(@challenge.start_date, "%b %d")} → {Calendar.strftime(@challenge.end_date, "%b %d, %Y")}
                · {min(@elapsed || 0, @total || 0)}/{@total || 66} days
              <% else %>
                {if @total, do: "#{@total} day challenge", else: "66 day challenge"}
              <% end %>
            </div>
          </div>

          <%!-- Progress Ring + Status (desktop) --%>
          <div class="hidden sm:flex items-center gap-3.5 flex-shrink-0">
            <%!-- SVG Progress Ring --%>
            <div class="relative w-12 h-12">
              <svg width="48" height="48" class="-rotate-90">
                <circle
                  cx="24" cy="24" r="20"
                  fill="none"
                  stroke="rgba(255,255,255,0.05)"
                  stroke-width="4"
                />
                <circle
                  cx="24" cy="24" r="20"
                  fill="none"
                  stroke={status_color(@challenge.status)}
                  stroke-width="4"
                  stroke-linecap="round"
                  stroke-dasharray={@circumference}
                  stroke-dashoffset={@stroke_offset}
                />
              </svg>
              <span
                class="absolute inset-0 flex items-center justify-center font-['Bebas_Neue'] text-[0.75rem]"
                style={"color: #{status_color(@challenge.status)}"}
              >
                {@progress}%
              </span>
            </div>

            <%!-- Status Badge --%>
            <span class={[
              "text-[0.6rem] uppercase tracking-[2px] font-bold py-[5px] px-3 rounded-full whitespace-nowrap",
              status_badge_class(@challenge.status)
            ]}>
              {status_label(@challenge.status)}
            </span>
          </div>

          <%!-- Status (mobile only) --%>
          <div class="flex sm:hidden flex-shrink-0">
            <span class={[
              "text-[0.55rem] uppercase tracking-[1.5px] font-bold py-1 px-2.5 rounded-full",
              status_badge_class(@challenge.status)
            ]}>
              {status_label(@challenge.status)}
            </span>
          </div>
        </div>
      </div>
    </.link>
    """
  end

  defp status_color(:active), do: "#ff4d00"
  defp status_color(:completed), do: "#22c55e"
  defp status_color(:failed), do: "#ef4444"
  defp status_color(:cancelled), do: "#5a5754"
  defp status_color(_), do: "#ff4d00"

  defp status_badge_class(:active), do: "text-t66-accent bg-[rgba(255,77,0,0.15)]"
  defp status_badge_class(:completed), do: "text-[#22c55e] bg-[rgba(34,197,94,0.12)]"
  defp status_badge_class(:failed), do: "text-[#ef4444] bg-[rgba(239,68,68,0.12)]"
  defp status_badge_class(:cancelled), do: "text-t66-text-muted bg-white/[0.04]"
  defp status_badge_class(_), do: "text-t66-accent bg-[rgba(255,77,0,0.15)]"

  defp status_label(:active), do: "In Progress"
  defp status_label(:completed), do: "Completed"
  defp status_label(:failed), do: "Didn't Finish"
  defp status_label(:cancelled), do: "Cancelled"
  defp status_label(_), do: "In Progress"
end
