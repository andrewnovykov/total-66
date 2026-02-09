defmodule HeadsUpWeb.ChallengeLive.Index do
  use HeadsUpWeb, :live_view
  alias HeadsUp.Challenges

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns[:current_user]

    templates =
      if current_user do
        Challenges.list_visible_challenges(current_user.id)
      else
        Challenges.list_public_challenges()
      end

    categories = Challenges.list_active_categories()

    socket =
      socket
      |> assign(:templates, templates)
      |> assign(:filtered_challenges, templates)
      |> assign(:categories, categories)
      |> assign(:filter_type, "all")
      |> assign(:filter_category, "all")
      |> assign(:search_query, "")
      |> assign(:page_title, "Challenges")

    {:ok, socket, layout: {HeadsUpWeb.Layouts, :public}}
  end

  @impl true
  def handle_event("filter_type", %{"type" => type}, socket) do
    filtered =
      filter_challenges(
        socket.assigns.templates,
        type,
        socket.assigns.filter_category,
        socket.assigns.search_query
      )

    {:noreply,
     socket
     |> assign(:filtered_challenges, filtered)
     |> assign(:filter_type, type)}
  end

  @impl true
  def handle_event("filter_category", %{"category" => category}, socket) do
    filtered =
      filter_challenges(
        socket.assigns.templates,
        socket.assigns.filter_type,
        category,
        socket.assigns.search_query
      )

    {:noreply,
     socket
     |> assign(:filtered_challenges, filtered)
     |> assign(:filter_category, category)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    filtered =
      filter_challenges(
        socket.assigns.templates,
        socket.assigns.filter_type,
        socket.assigns.filter_category,
        query
      )

    {:noreply,
     socket
     |> assign(:filtered_challenges, filtered)
     |> assign(:search_query, query)}
  end

  @impl true
  def handle_event("join_challenge", %{"id" => id}, socket) do
    current_user = socket.assigns.current_user

    if current_user do
      case Challenges.join_challenge(String.to_integer(id), current_user.id) do
        {:ok, _participant} ->
          {:noreply,
           socket
           |> put_flash(:info, "Successfully joined the challenge!")
           |> push_navigate(to: ~p"/challenges/#{id}")}

        {:error, :already_joined} ->
          {:noreply, put_flash(socket, :error, "You've already joined this challenge.")}

        {:error, :active_limit_reached} ->
          {:noreply,
           put_flash(socket, :error, "You've reached the maximum of 3 active goals/challenges.")}

        {:error, :access_denied} ->
          {:noreply, put_flash(socket, :error, "You don't have access to this challenge.")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Could not join challenge.")}
      end
    else
      {:noreply, push_navigate(socket, to: ~p"/users/log_in")}
    end
  end

  defp filter_challenges(challenges, type, category, query) do
    challenges
    |> filter_by_type(type)
    |> filter_by_category(category)
    |> filter_by_search(query)
  end

  defp filter_by_type(challenges, "all"), do: challenges

  defp filter_by_type(challenges, "predefined"),
    do: Enum.filter(challenges, &(&1.type == :predefined))

  defp filter_by_type(challenges, "custom"), do: Enum.filter(challenges, &(&1.type == :custom))

  defp filter_by_category(challenges, "all"), do: challenges

  defp filter_by_category(challenges, category_id) do
    {id, _} = Integer.parse(category_id)
    Enum.filter(challenges, &(&1.category_id == id))
  end

  defp filter_by_search(challenges, ""), do: challenges

  defp filter_by_search(challenges, query) do
    query = String.downcase(query)

    Enum.filter(challenges, fn c ->
      String.contains?(String.downcase(c.title), query) ||
        (c.description && String.contains?(String.downcase(c.description), query))
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%!-- Page Header --%>
    <div class="pt-[60px] pb-[40px] sm:pb-[60px] px-5 sm:px-10 max-w-[1300px] mx-auto relative bg-[#0a0a0a]">
      <%!-- "CHALLENGES" watermark --%>
      <div class="absolute top-[80px] left-5 sm:left-10 font-['Bebas_Neue'] text-[clamp(80px,15vw,240px)] text-[rgba(255,77,0,0.03)] pointer-events-none leading-none tracking-[10px] select-none">CHALLENGES</div>

      <p class="text-[0.7rem] tracking-[4px] uppercase text-t66-accent mb-4 relative">Browse & Explore</p>
      <h1 class="font-['Bebas_Neue'] text-[clamp(2.5rem,5vw,4rem)] tracking-[3px] leading-[1.1] mb-3 text-[#f0ece6] relative">Challenges</h1>
      <p class="text-t66-text-secondary text-[1.05rem] max-w-[600px] relative">
        Browse challenge templates and start your journey toward personal growth. Pick an official challenge or explore community creations.
      </p>
    </div>

    <%!-- Search + Actions Bar --%>
    <div class="max-w-[1300px] mx-auto px-5 sm:px-10 mb-10">
      <div class="flex flex-col sm:flex-row gap-3 max-w-3xl">
        <div class="flex-1 relative">
          <.icon name="hero-magnifying-glass" class="w-5 h-5 absolute left-4 top-1/2 -translate-y-1/2 text-t66-text-muted" />
          <input
            type="text"
            phx-keyup="search"
            phx-debounce="300"
            name="query"
            value={@search_query}
            placeholder="Search challenges..."
            class="w-full pl-12 pr-5 py-3.5 bg-t66-input border border-white/[0.08] rounded-xl text-[#f0ece6] text-[0.9rem] placeholder:text-t66-text-muted focus:border-[rgba(255,77,0,0.4)] focus:ring-[3px] focus:ring-[rgba(255,77,0,0.08)] outline-none transition-all"
          />
        </div>
        <%= if @current_user do %>
          <.link
            navigate={~p"/challenges/new"}
            class="inline-flex items-center justify-center gap-2 bg-t66-accent text-white px-6 py-3.5 rounded-xl font-bold text-[0.85rem] tracking-[1px] uppercase hover:-translate-y-0.5 hover:shadow-[0_0_50px_rgba(255,77,0,0.35)] transition-all shadow-[0_0_30px_rgba(255,77,0,0.2)] no-underline flex-shrink-0"
          >
            <.icon name="hero-plus" class="w-5 h-5" /> Create Challenge
          </.link>
        <% end %>
      </div>
    </div>

    <%!-- Filter Row --%>
    <div class="max-w-[1300px] mx-auto px-5 sm:px-10 mb-8">
      <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div class="flex items-center gap-3">
          <h2 class="font-['Bebas_Neue'] text-[1.6rem] tracking-[2px] text-[#f0ece6]">
            {case @filter_type do
              "predefined" -> "Official Challenges"
              "custom" -> "Community Challenges"
              _ -> "All Challenges"
            end}
          </h2>
          <span class="text-t66-text-muted text-sm font-medium">
            {length(@filtered_challenges)} challenges
          </span>
        </div>

        <div class="flex items-center gap-3 flex-wrap">
          <%!-- Hidden select for test compatibility --%>
          <select phx-change="filter_type" name="type" class="sr-only" id="type-filter-select">
            <option value="all" selected={@filter_type == "all"}>All Types</option>
            <option value="predefined" selected={@filter_type == "predefined"}>Official</option>
            <option value="custom" selected={@filter_type == "custom"}>Community</option>
          </select>

          <%!-- Visual Filter Pills --%>
          <div class="flex gap-2">
            <button
              phx-click="filter_type"
              phx-value-type="all"
              class={[
                "px-5 py-2 rounded-xl text-sm font-bold transition-all border",
                if(@filter_type == "all",
                  do: "bg-t66-accent text-white border-t66-accent shadow-[0_0_20px_rgba(255,77,0,0.15)]",
                  else: "bg-t66-card text-t66-text-secondary border-white/[0.06] hover:border-white/[0.12] hover:text-[#f0ece6]"
                )
              ]}
            >
              All
            </button>
            <button
              phx-click="filter_type"
              phx-value-type="predefined"
              class={[
                "px-5 py-2 rounded-xl text-sm font-bold transition-all border",
                if(@filter_type == "predefined",
                  do: "bg-t66-accent text-white border-t66-accent shadow-[0_0_20px_rgba(255,77,0,0.15)]",
                  else: "bg-t66-card text-t66-text-secondary border-white/[0.06] hover:border-white/[0.12] hover:text-[#f0ece6]"
                )
              ]}
            >
              Official
            </button>
            <button
              phx-click="filter_type"
              phx-value-type="custom"
              class={[
                "px-5 py-2 rounded-xl text-sm font-bold transition-all border",
                if(@filter_type == "custom",
                  do: "bg-t66-accent text-white border-t66-accent shadow-[0_0_20px_rgba(255,77,0,0.15)]",
                  else: "bg-t66-card text-t66-text-secondary border-white/[0.06] hover:border-white/[0.12] hover:text-[#f0ece6]"
                )
              ]}
            >
              Community
            </button>
          </div>

          <%!-- Category Filter --%>
          <%= if @categories != [] do %>
            <select
              phx-change="filter_category"
              name="category"
              class="bg-t66-card border border-white/[0.06] rounded-xl px-4 py-2 text-sm font-bold text-t66-text-secondary focus:border-[rgba(255,77,0,0.4)] focus:ring-[3px] focus:ring-[rgba(255,77,0,0.08)] cursor-pointer outline-none appearance-none"
            >
              <option value="all" selected={@filter_category == "all"}>All Categories</option>
              <%= for category <- @categories do %>
                <option value={category.id} selected={@filter_category == to_string(category.id)}>
                  {category.name}
                </option>
              <% end %>
            </select>
          <% end %>
        </div>
      </div>
    </div>

    <%!-- My Challenges Link --%>
    <%= if @current_user do %>
      <div class="max-w-[1300px] mx-auto px-5 sm:px-10 mb-6">
        <.link
          navigate={~p"/my-challenges"}
          class="inline-flex items-center gap-2 text-t66-accent hover:text-t66-accent-secondary font-bold text-sm transition-colors no-underline"
        >
          <.icon name="hero-folder" class="w-4 h-4" /> View My Challenges
          <.icon name="hero-chevron-right" class="w-4 h-4" />
        </.link>
      </div>
    <% end %>

    <%!-- Challenges Grid --%>
    <div class="max-w-[1300px] mx-auto px-5 sm:px-10 pb-20">
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <%= for challenge <- @filtered_challenges do %>
          <.challenge_card challenge={challenge} current_user={@current_user} />
        <% end %>
      </div>

      <%!-- Empty State --%>
      <%= if @filtered_challenges == [] do %>
        <div class="bg-t66-card border border-white/[0.06] rounded-2xl p-12 text-center">
          <div class="w-16 h-16 mx-auto bg-white/[0.04] rounded-2xl flex items-center justify-center mb-4">
            <.icon name="hero-bolt" class="w-8 h-8 text-t66-text-muted" />
          </div>
          <h3 class="text-xl font-bold text-[#f0ece6] mb-2">No challenges found</h3>
          <p class="text-t66-text-muted mb-6">Try adjusting your filters or search query.</p>
          <button
            phx-click="filter_type"
            phx-value-type="all"
            class="inline-flex items-center gap-2 bg-t66-accent text-white px-6 py-3 rounded-xl font-bold text-sm tracking-[1px] uppercase hover:-translate-y-0.5 transition-all shadow-[0_0_30px_rgba(255,77,0,0.2)]"
          >
            Show All Challenges
          </button>
        </div>
      <% end %>
    </div>
    """
  end

  defp challenge_card(assigns) do
    derived =
      if Ecto.assoc_loaded?(assigns.challenge.derived_challenges),
        do: assigns.challenge.derived_challenges,
        else: []

    total = length(derived)
    completed = Enum.count(derived, &(&1.status == :completed))
    failed = Enum.count(derived, &(&1.status in [:failed, :cancelled]))
    finished = completed + failed
    success_rate = if finished > 0, do: Float.round(completed / finished * 100, 0), else: 0.0

    assigns =
      assigns
      |> Map.put(:total_started, total)
      |> Map.put(:success_rate, success_rate)
      |> Map.put(:has_completions, finished > 0)

    ~H"""
    <.link navigate={~p"/challenges/#{@challenge.id}"} class="block cursor-pointer group no-underline">
      <div class="bg-t66-card border border-white/[0.06] rounded-2xl overflow-hidden h-full transition-all hover:border-white/[0.12] hover:-translate-y-0.5 hover:shadow-[0_16px_40px_rgba(0,0,0,0.3)]">
        <%!-- Top accent bar --%>
        <div class={[
          "h-[3px]",
          if(@challenge.type == :predefined,
            do: "bg-gradient-to-r from-t66-accent via-t66-accent-secondary to-t66-accent",
            else: "bg-gradient-to-r from-t66-cyan via-t66-purple to-t66-cyan"
          )
        ]}></div>

        <%!-- Card header with icon --%>
        <div class={[
          "px-5 pt-5 pb-3 flex items-center gap-3",
        ]}>
          <div class={[
            "w-11 h-11 rounded-xl flex items-center justify-center flex-shrink-0",
            if(@challenge.type == :predefined,
              do: "bg-[rgba(255,77,0,0.15)]",
              else: "bg-[rgba(0,212,170,0.12)]"
            )
          ]}>
            <.icon name="hero-bolt-solid" class={[
              "w-5 h-5",
              if(@challenge.type == :predefined, do: "text-t66-accent", else: "text-t66-cyan")
            ]} />
          </div>
          <div class="flex-1 min-w-0">
            <h3 class="text-[0.95rem] font-bold text-[#f0ece6] truncate group-hover:text-t66-accent transition-colors">
              {@challenge.title}
            </h3>
            <div class="flex items-center gap-2 mt-0.5">
              <span class={[
                "px-2 py-0.5 text-[0.6rem] font-bold rounded-full uppercase tracking-[1px]",
                if(@challenge.type == :predefined,
                  do: "bg-[rgba(255,77,0,0.15)] text-t66-accent",
                  else: "bg-[rgba(0,212,170,0.12)] text-t66-cyan"
                )
              ]}>
                {if @challenge.type == :predefined, do: "Official", else: "Community"}
              </span>
              <%= if @challenge.category do %>
                <span class="px-2 py-0.5 text-[0.6rem] font-bold rounded-full bg-white/[0.04] text-t66-text-muted uppercase tracking-[1px]">
                  {@challenge.category.name}
                </span>
              <% end %>
            </div>
          </div>
        </div>

        <%!-- Description --%>
        <%= if @challenge.description do %>
          <div class="px-5 pb-3">
            <p class="text-t66-text-muted text-[0.8rem] leading-relaxed line-clamp-2">
              {@challenge.description}
            </p>
          </div>
        <% end %>

        <%!-- Stats Bar --%>
        <div class="px-5 pb-5 pt-2">
          <div class="flex items-center gap-4 pt-3 border-t border-white/[0.06]">
            <%= if @challenge.duration_days do %>
              <span class="flex items-center gap-1.5 text-[0.75rem] text-t66-text-muted font-semibold">
                <.icon name="hero-clock" class="w-3.5 h-3.5 text-t66-accent" />
                {@challenge.duration_days}d
              </span>
            <% end %>
            <span class="flex items-center gap-1.5 text-[0.75rem] text-t66-text-muted font-semibold">
              <.icon name="hero-user-group" class="w-3.5 h-3.5 text-t66-purple" />
              {@total_started} started
            </span>
            <span class={[
              "flex items-center gap-1.5 text-[0.75rem] font-semibold",
              if(@has_completions, do: "text-green-500", else: "text-t66-text-muted")
            ]}>
              <.icon name="hero-trophy" class={[
                "w-3.5 h-3.5",
                if(@has_completions, do: "text-t66-gold", else: "text-t66-text-muted")
              ]} />
              <%= if @has_completions do %>
                {trunc(@success_rate)}%
              <% else %>
                —
              <% end %>
            </span>
          </div>
        </div>
      </div>
    </.link>
    """
  end
end
