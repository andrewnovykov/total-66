defmodule HeadsUpWeb.UsersLive.Index do
  use HeadsUpWeb, :live_view
  alias HeadsUp.{Accounts, Repo}
  import Ecto.Query

  def mount(_params, _session, socket) do
    users = Accounts.list_users() |> add_challenge_stats()

    finisher_count = Enum.count(users, & &1.is_finisher)
    total_attempts = Enum.reduce(users, 0, fn u, acc -> acc + u.challenge_count end)

    socket =
      socket
      |> assign(:users, users)
      |> assign(:filtered_users, users)
      |> assign(:search_query, "")
      |> assign(:filter_type, "all")
      |> assign(:finisher_count, finisher_count)
      |> assign(:total_attempts, total_attempts)

    {:ok, socket, layout: {HeadsUpWeb.Layouts, :public}}
  end

  def handle_event("search", %{"search" => %{"query" => query}}, socket) do
    filtered_users = filter_users(socket.assigns.users, query, socket.assigns.filter_type)

    socket =
      socket
      |> assign(:search_query, query)
      |> assign(:filtered_users, filtered_users)

    {:noreply, socket}
  end

  def handle_event("filter", %{"type" => type}, socket) do
    filtered_users = filter_users(socket.assigns.users, socket.assigns.search_query, type)

    socket =
      socket
      |> assign(:filter_type, type)
      |> assign(:filtered_users, filtered_users)

    {:noreply, socket}
  end

  defp filter_users(users, query, type) do
    users
    |> filter_by_search(query)
    |> filter_by_type(type)
  end

  defp filter_by_search(users, ""), do: users

  defp filter_by_search(users, query) do
    search_term = String.downcase(query)

    Enum.filter(users, fn user ->
      name_match = String.contains?(String.downcase(user.name || ""), search_term)
      username_match = String.contains?(String.downcase(user.user_name || ""), search_term)
      name_match || username_match
    end)
  end

  defp filter_by_type(users, "finisher"), do: Enum.filter(users, & &1.is_finisher)
  defp filter_by_type(users, "active"), do: Enum.filter(users, &(!&1.is_finisher))
  defp filter_by_type(users, _), do: users

  def render(assigns) do
    ~H"""
    <div class="min-h-screen">
      <%!-- PAGE HEADER with watermark --%>
      <div class="relative pt-10 pb-10 lg:pt-16 lg:pb-14 px-5 sm:px-10 max-w-[1200px] mx-auto">
        <%!-- Watermark --%>
        <div
          class="absolute top-2 left-5 sm:left-10 pointer-events-none select-none font-display leading-none tracking-[10px]"
          style="font-size: clamp(120px, 18vw, 280px); color: rgba(255, 77, 0, 0.03);"
        >
          MEMBERS
        </div>

        <div class="relative z-10">
          <p class="text-[0.7rem] tracking-[4px] uppercase text-t66-accent font-bold mb-4">
            Community
          </p>
          <h1
            class="font-display tracking-[3px] mb-3 leading-[1.1] text-t66-text"
            style="font-size: clamp(2.5rem, 5vw, 4rem);"
          >
            Our Members
          </h1>
          <p class="text-t66-text-secondary max-w-[500px] text-[1.05rem]">
            Meet the warriors who committed to transforming their lives. 66 days. No excuses.
          </p>
        </div>
      </div>

      <%!-- STATS BAR --%>
      <div class="max-w-[1200px] mx-auto mb-10 px-5 sm:px-10 flex gap-6 flex-wrap">
        <div class="flex items-center gap-2.5 px-5 py-3 bg-t66-card border border-t66 rounded-full">
          <span class="font-display text-[1.5rem] leading-none text-t66-accent">
            {length(@users)}
          </span>
          <span class="text-[0.75rem] uppercase tracking-[1px] text-t66-text-muted">Members</span>
        </div>
        <div class="flex items-center gap-2.5 px-5 py-3 bg-t66-card border border-t66 rounded-full">
          <span class="font-display text-[1.5rem] leading-none text-t66-accent">
            {@finisher_count}
          </span>
          <span class="text-[0.75rem] uppercase tracking-[1px] text-t66-text-muted">
            Finishers
          </span>
        </div>
        <div class="flex items-center gap-2.5 px-5 py-3 bg-t66-card border border-t66 rounded-full">
          <span class="font-display text-[1.5rem] leading-none text-t66-accent">
            {@total_attempts}
          </span>
          <span class="text-[0.75rem] uppercase tracking-[1px] text-t66-text-muted">
            Total Attempts
          </span>
        </div>
      </div>

      <%!-- TOOLBAR: Search + Filters --%>
      <div class="max-w-[1200px] mx-auto mb-10 px-5 sm:px-10 flex gap-3 flex-wrap items-center">
        <%!-- Search --%>
        <div class="flex-1 min-w-[220px] relative">
          <.form for={%{}} phx-change="search">
            <div class="relative">
              <span class="absolute left-[18px] top-1/2 -translate-y-1/2 text-[0.9rem] pointer-events-none">
                <.icon name="hero-magnifying-glass" class="w-4 h-4 text-t66-text-muted" />
              </span>
              <input
                name="search[query]"
                placeholder="Search members..."
                class="w-full py-3.5 pl-12 pr-5 bg-t66-card border border-t66 rounded-xl text-t66-text font-body text-[0.9rem] outline-none transition-colors focus:border-[rgba(255,77,0,0.4)] placeholder:text-t66-text-muted"
                value={@search_query}
              />
            </div>
          </.form>
        </div>
        <%!-- Filter Buttons --%>
        <button
          phx-click="filter"
          phx-value-type="all"
          class={[
            "py-3.5 px-5 border rounded-xl text-[0.8rem] tracking-[1px] uppercase cursor-pointer transition-all font-body font-medium",
            if(@filter_type == "all",
              do: "border-t66-accent text-t66-accent bg-t66-accent-glow",
              else: "bg-t66-card border-t66 text-t66-text-secondary hover:border-[rgba(255,255,255,0.15)] hover:text-t66-text"
            )
          ]}
        >
          All
        </button>
        <button
          phx-click="filter"
          phx-value-type="finisher"
          class={[
            "py-3.5 px-5 border rounded-xl text-[0.8rem] tracking-[1px] uppercase cursor-pointer transition-all font-body font-medium",
            if(@filter_type == "finisher",
              do: "border-t66-accent text-t66-accent bg-t66-accent-glow",
              else: "bg-t66-card border-t66 text-t66-text-secondary hover:border-[rgba(255,255,255,0.15)] hover:text-t66-text"
            )
          ]}
        >
          Finishers
        </button>
        <button
          phx-click="filter"
          phx-value-type="active"
          class={[
            "py-3.5 px-5 border rounded-xl text-[0.8rem] tracking-[1px] uppercase cursor-pointer transition-all font-body font-medium",
            if(@filter_type == "active",
              do: "border-t66-accent text-t66-accent bg-t66-accent-glow",
              else: "bg-t66-card border-t66 text-t66-text-secondary hover:border-[rgba(255,255,255,0.15)] hover:text-t66-text"
            )
          ]}
        >
          In Progress
        </button>
      </div>

      <%!-- MEMBERS GRID --%>
      <%= if Enum.empty?(@filtered_users) do %>
        <div class="max-w-[1200px] mx-auto px-5 sm:px-10 pb-24">
          <div class="bg-t66-card border border-t66 rounded-2xl p-10 text-center">
            <div class="w-14 h-14 rounded-xl bg-[rgba(255,255,255,0.03)] flex items-center justify-center mx-auto mb-4">
              <.icon name="hero-users" class="w-7 h-7 text-t66-text-muted" />
            </div>
            <p class="text-t66-text font-bold mb-2">
              <%= if @search_query != "" do %>
                No members found matching "{@search_query}"
              <% else %>
                No members to display
              <% end %>
            </p>
            <p class="text-t66-text-muted text-sm">
              Try adjusting your search or filters
            </p>
          </div>
        </div>
      <% else %>
        <div class="max-w-[1200px] mx-auto px-5 sm:px-10 pb-24 grid gap-5" style="grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));">
          <%= for user <- @filtered_users do %>
            <.link
              navigate={~p"/people/#{user.user_name || "user-#{user.id}"}"}
              class={[
                "bg-t66-card border rounded-2xl p-8 pb-7 flex flex-col items-center text-center transition-all duration-[400ms] relative overflow-hidden group",
                "hover:-translate-y-1.5 hover:shadow-t66-card",
                if(user.is_finisher,
                  do: "border-[rgba(255,198,66,0.12)] hover:border-[rgba(255,198,66,0.25)]",
                  else: "border-t66 hover:border-[rgba(255,77,0,0.15)]"
                )
              ]}
            >
              <%!-- Top accent line --%>
              <div class={[
                "absolute top-0 left-0 right-0 h-[3px] transition-all duration-[400ms]",
                if(user.is_finisher,
                  do: "bg-gradient-to-r from-transparent via-t66-gold to-transparent",
                  else: "bg-gradient-to-r from-transparent via-[rgba(255,255,255,0.06)] to-transparent group-hover:via-t66-accent"
                )
              ]} />

              <%!-- Avatar (initials only) --%>
              <div class="relative mb-5">
                <div class={[
                  "w-20 h-20 rounded-full border-[3px] flex items-center justify-center font-display text-[1.6rem] tracking-[2px] text-t66-text-muted bg-[rgba(255,255,255,0.03)] transition-colors duration-300",
                  if(user.is_finisher,
                    do: "border-[rgba(255,198,66,0.3)] group-hover:border-t66-gold",
                    else: "border-t66 group-hover:border-t66-accent"
                  )
                ]}>
                  {get_initials(user.name || user.user_name || "U")}
                </div>
                <%!-- Finisher badge on avatar --%>
                <%= if user.is_finisher do %>
                  <div class="absolute -bottom-1 -right-1 w-[30px] h-[30px] bg-t66-gold rounded-full flex items-center justify-center text-[0.8rem] shadow-t66-gold border-[3px] border-t66-card">
                    <span>&#127942;</span>
                  </div>
                <% end %>
              </div>

              <%!-- Name & Nickname --%>
              <p class="font-bold text-[1.05rem] text-t66-text mb-0.5 truncate max-w-full">
                {user.name || user.user_name || "Anonymous"}
              </p>
              <p class="text-t66-text-muted text-[0.85rem] mb-4">
                @{user.user_name || "unknown"}
              </p>

              <%!-- Finisher / In Progress Tag --%>
              <%= if user.is_finisher do %>
                <span class="inline-flex items-center gap-1.5 mb-4 px-3 py-1 rounded-full text-[0.65rem] uppercase tracking-[2px] font-bold text-t66-gold bg-t66-gold-glow">
                  <span>&#127942;</span> Finisher
                </span>
              <% else %>
                <span class="inline-flex items-center gap-1.5 mb-4 px-3 py-1 rounded-full text-[0.65rem] uppercase tracking-[2px] font-bold text-t66-text-muted bg-[rgba(255,255,255,0.03)]">
                  In Progress
                </span>
              <% end %>

              <%!-- Stats --%>
              <div class="flex gap-5 w-full justify-center pt-4 border-t border-t66">
                <div class="flex flex-col items-center">
                  <span class={[
                    "font-display text-[1.5rem] leading-[1.1]",
                    if(user.is_finisher, do: "text-t66-gold", else: "text-t66-accent")
                  ]}>
                    {user.challenge_count}
                  </span>
                  <span class="text-[0.65rem] uppercase tracking-[1.5px] text-t66-text-muted">
                    Attempts
                  </span>
                </div>
                <div class="flex flex-col items-center">
                  <span class={[
                    "font-display text-[1.5rem] leading-[1.1]",
                    if(user.is_finisher, do: "text-t66-gold", else: "text-t66-accent")
                  ]}>
                    <%= if user.best_day > 0, do: user.best_day, else: raw("&mdash;") %>
                  </span>
                  <span class="text-[0.65rem] uppercase tracking-[1.5px] text-t66-text-muted">
                    Best Day
                  </span>
                </div>
              </div>
            </.link>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp add_challenge_stats(users) do
    user_ids = Enum.map(users, & &1.id)

    # Get challenge participation counts per user
    counts =
      from(cp in HeadsUp.Challenges.ChallengeParticipant,
        where: cp.user_id in ^user_ids,
        group_by: cp.user_id,
        select: {cp.user_id, count(cp.id)}
      )
      |> Repo.all()
      |> Map.new()

    # Get finisher status (completed any challenge)
    finishers =
      from(cp in HeadsUp.Challenges.ChallengeParticipant,
        where: cp.user_id in ^user_ids and cp.status == :completed,
        distinct: cp.user_id,
        select: cp.user_id
      )
      |> Repo.all()
      |> MapSet.new()

    # Get best day (max check-in day number) per user
    best_days =
      from(ci in HeadsUp.Challenges.DailyCheckIn,
        where: ci.user_id in ^user_ids,
        group_by: ci.user_id,
        select: {ci.user_id, max(ci.day_number)}
      )
      |> Repo.all()
      |> Map.new()

    Enum.map(users, fn user ->
      user
      |> Map.put(:challenge_count, Map.get(counts, user.id, 0))
      |> Map.put(:is_finisher, MapSet.member?(finishers, user.id))
      |> Map.put(:best_day, Map.get(best_days, user.id, 0))
    end)
  end

  defp get_initials(name) do
    name
    |> String.split(" ", trim: true)
    |> Enum.take(2)
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
  end
end
