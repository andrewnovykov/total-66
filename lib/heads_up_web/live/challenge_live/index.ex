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

    {:ok, socket}
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
    <div class="flex gap-0 h-full">
      <%!-- ===== CENTER CONTENT ===== --%>
      <div class="flex-grow p-5 sm:p-8 lg:p-10 overflow-y-auto custom-scrollbar">
        <%!-- Hero Banner --%>
        <div class="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-[40px] p-8 sm:p-10 lg:p-12 mb-10 relative overflow-hidden text-white soft-shadow">
          <div class="relative z-10">
            <span class="bg-blue-500/50 text-blue-100 text-xs font-bold px-4 py-1.5 rounded-full mb-4 inline-block uppercase tracking-wider">
              Browse
            </span>
            <h1 class="text-3xl sm:text-4xl lg:text-5xl font-extrabold mb-4 leading-tight">
              Challenges
            </h1>
            <p class="text-blue-100 text-lg leading-relaxed max-w-xl mb-8">
              Browse challenge templates and start your journey toward personal growth.
            </p>

            <%!-- Search Bar --%>
            <div class="flex flex-col sm:flex-row gap-3 max-w-2xl">
              <div class="flex-1 relative">
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
                  placeholder="Search challenges..."
                  class="w-full pl-12 pr-5 py-4 bg-white/15 backdrop-blur-sm text-white placeholder-blue-200 border border-white/20 rounded-2xl text-base focus:outline-none focus:ring-2 focus:ring-white/30 focus:bg-white/20 transition"
                />
              </div>
              <%= if @current_user do %>
                <.link
                  navigate={~p"/challenges/new"}
                  class="inline-flex items-center justify-center gap-2 bg-white text-blue-600 px-8 py-4 rounded-2xl font-bold text-base hover:scale-105 transition-all duration-200 soft-shadow flex-shrink-0"
                >
                  <.icon name="hero-plus" class="w-5 h-5" /> Create Challenge
                </.link>
              <% end %>
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
              {case @filter_type do
                "predefined" -> "Official Challenges"
                "custom" -> "Community Challenges"
                _ -> "All Challenges"
              end}
            </h2>
            <span class="text-slate-400 text-sm font-medium">
              {length(@filtered_challenges)} challenges
            </span>
          </div>

          <div class="flex items-center gap-3 flex-wrap">
            <%!-- Type Filter - hidden select for test compat, visible as pills --%>
            <select phx-change="filter_type" name="type" class="sr-only" id="type-filter-select">
              <option value="all" selected={@filter_type == "all"}>All Types</option>
              <option value="predefined" selected={@filter_type == "predefined"}>Official</option>
              <option value="custom" selected={@filter_type == "custom"}>Community</option>
            </select>

            <%!-- Visual Type Pills --%>
            <div class="flex gap-2">
              <button
                phx-click="filter_type"
                phx-value-type="all"
                class={[
                  "px-5 py-2.5 rounded-xl text-sm font-bold transition-all",
                  if(@filter_type == "all",
                    do: "bg-slate-900 text-white",
                    else: "bg-white text-slate-500 soft-shadow hover:bg-slate-50"
                  )
                ]}
              >
                All
              </button>
              <button
                phx-click="filter_type"
                phx-value-type="predefined"
                class={[
                  "px-5 py-2.5 rounded-xl text-sm font-bold transition-all",
                  if(@filter_type == "predefined",
                    do: "bg-slate-900 text-white",
                    else: "bg-white text-slate-500 soft-shadow hover:bg-slate-50"
                  )
                ]}
              >
                Official
              </button>
              <button
                phx-click="filter_type"
                phx-value-type="custom"
                class={[
                  "px-5 py-2.5 rounded-xl text-sm font-bold transition-all",
                  if(@filter_type == "custom",
                    do: "bg-slate-900 text-white",
                    else: "bg-white text-slate-500 soft-shadow hover:bg-slate-50"
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
                class="bg-white border-0 rounded-xl px-5 py-2.5 text-sm font-bold text-slate-600 soft-shadow focus:ring-2 focus:ring-blue-500/30 cursor-pointer"
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

        <%!-- My Challenges Link --%>
        <%= if @current_user do %>
          <div class="mb-6">
            <.link
              navigate={~p"/my-challenges"}
              class="inline-flex items-center gap-2 text-blue-600 hover:text-blue-700 font-bold text-sm transition-colors"
            >
              <.icon name="hero-folder" class="w-4 h-4" /> View My Challenges
              <.icon name="hero-chevron-right" class="w-4 h-4" />
            </.link>
          </div>
        <% end %>

        <%!-- Challenges Grid --%>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <%= for challenge <- @filtered_challenges do %>
            <.challenge_card challenge={challenge} current_user={@current_user} />
          <% end %>
        </div>

        <%!-- Empty State --%>
        <%= if @filtered_challenges == [] do %>
          <HeadsUpWeb.Components.UI.Card.card padding={:lg} class="text-center">
            <div class="py-8">
              <div class="w-16 h-16 mx-auto bg-slate-100 rounded-2xl flex items-center justify-center mb-4">
                <.icon name="hero-bolt" class="w-8 h-8 text-slate-400" />
              </div>
              <h3 class="text-xl font-extrabold text-slate-900 mb-2">No challenges found</h3>
              <p class="text-slate-500 mb-6">Try adjusting your filters or search query.</p>
              <button
                phx-click="filter_type"
                phx-value-type="all"
                class="inline-flex items-center gap-2 bg-gradient-to-r from-blue-500 to-indigo-600 text-white px-6 py-3 rounded-2xl font-bold hover:scale-105 transition-all"
              >
                Show All Challenges
              </button>
            </div>
          </HeadsUpWeb.Components.UI.Card.card>
        <% end %>
      </div>

      <%!-- ===== RIGHT SIDEBAR ===== --%>
      <aside class="hidden xl:flex flex-col w-[420px] flex-shrink-0 bg-white border-l border-slate-100 p-8 overflow-y-auto custom-scrollbar gap-10">
        <%!-- Categories --%>
        <%= if @categories != [] do %>
          <div>
            <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Categories</h3>
            <div class="space-y-3">
              <%= for category <- @categories do %>
                <button
                  phx-click="filter_category"
                  phx-value-category={category.id}
                  class={[
                    "w-full flex items-center gap-4 p-4 rounded-2xl transition-colors text-left",
                    if(@filter_category == to_string(category.id),
                      do: "bg-blue-50 border border-blue-200",
                      else: "bg-slate-50 hover:bg-slate-100"
                    )
                  ]}
                >
                  <div class="w-10 h-10 bg-indigo-50 rounded-xl flex items-center justify-center flex-shrink-0">
                    <.icon name="hero-tag" class="w-5 h-5 text-indigo-600" />
                  </div>
                  <span class={[
                    "font-bold text-sm",
                    if(@filter_category == to_string(category.id),
                      do: "text-blue-700",
                      else: "text-slate-700"
                    )
                  ]}>
                    {category.name}
                  </span>
                </button>
              <% end %>
            </div>
          </div>
        <% end %>

        <%!-- Quick Links --%>
        <div>
          <h3 class="text-2xl font-extrabold text-slate-900 mb-6">Quick Links</h3>
          <div class="space-y-3">
            <%= if @current_user do %>
              <.link
                navigate={~p"/my-challenges"}
                class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors group"
              >
                <div class="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center">
                  <.icon name="hero-folder" class="w-5 h-5 text-blue-600" />
                </div>
                <span class="font-bold text-slate-700 group-hover:text-slate-900">My Challenges</span>
                <.icon name="hero-chevron-right" class="w-5 h-5 text-slate-400 ml-auto" />
              </.link>
            <% end %>
            <.link
              navigate={~p"/all-goals"}
              class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors group"
            >
              <div class="w-10 h-10 bg-indigo-50 rounded-xl flex items-center justify-center">
                <.icon name="hero-fire" class="w-5 h-5 text-indigo-600" />
              </div>
              <span class="font-bold text-slate-700 group-hover:text-slate-900">Browse Goals</span>
              <.icon name="hero-chevron-right" class="w-5 h-5 text-slate-400 ml-auto" />
            </.link>
          </div>
        </div>

        <%!-- Start Challenge Promo --%>
        <%= if @current_user do %>
          <div class="bg-gradient-to-br from-blue-600 to-indigo-700 rounded-[32px] p-8 text-white">
            <div class="w-14 h-14 bg-white/20 rounded-2xl flex items-center justify-center mb-4">
              <.icon name="hero-rocket-launch" class="w-7 h-7 text-white" />
            </div>
            <h4 class="text-xl font-extrabold mb-2">Ready for a challenge?</h4>
            <p class="text-blue-100 text-sm mb-6">
              Create your own challenge and invite friends to join.
            </p>
            <.link
              navigate={~p"/challenges/new"}
              class="inline-flex items-center gap-2 bg-white text-blue-600 px-6 py-3 rounded-2xl font-bold text-sm hover:scale-105 transition-all"
            >
              <.icon name="hero-plus" class="w-4 h-4" /> Create Challenge
            </.link>
          </div>
        <% end %>
      </aside>
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
    <.link navigate={~p"/challenges/#{@challenge.id}"} class="block cursor-pointer group">
      <HeadsUpWeb.Components.UI.Card.card hover padding={:none} class="overflow-hidden h-full">
        <%!-- Challenge Image/Gradient --%>
        <div class="w-full h-36 bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center relative">
          <.icon name="hero-bolt" class="w-10 h-10 text-white/80" />
          <%!-- Type Badge Overlay --%>
          <span class={[
            "absolute top-3 left-3 px-3 py-1 text-xs font-bold rounded-full backdrop-blur-sm",
            if(@challenge.type == :predefined,
              do: "bg-purple-500/90 text-white",
              else: "bg-blue-400/90 text-white"
            )
          ]}>
            {if @challenge.type == :predefined, do: "Official", else: "Community"}
          </span>
        </div>

        <%!-- Content --%>
        <div class="p-5">
          <%!-- Badges --%>
          <div class="flex flex-wrap items-center gap-2 mb-2">
            <%= if @challenge.is_template do %>
              <span class="px-2.5 py-0.5 text-[11px] font-bold rounded-full bg-amber-50 text-amber-600">
                Template
              </span>
            <% else %>
              <HeadsUpWeb.Components.UI.StatusBadge.status_badge
                status={@challenge.status}
                size={:sm}
              />
            <% end %>
            <%= if @challenge.category do %>
              <span class="px-2.5 py-0.5 text-[11px] font-bold rounded-full bg-slate-100 text-slate-600">
                {@challenge.category.name}
              </span>
            <% end %>
          </div>

          <%!-- Title --%>
          <h3 class="text-base font-extrabold text-slate-900 mb-1 line-clamp-1 group-hover:text-blue-600 transition-colors">
            {@challenge.title}
          </h3>

          <%!-- Description --%>
          <%= if @challenge.description do %>
            <p class="text-slate-500 text-sm mb-3 line-clamp-2 leading-relaxed">
              {@challenge.description}
            </p>
          <% end %>

          <%!-- Stats Bar --%>
          <div class="flex items-center gap-3 pt-3 border-t border-slate-100">
            <%= if @challenge.duration_days do %>
              <span class="flex items-center gap-1 text-xs text-slate-500 font-semibold">
                <.icon name="hero-clock" class="w-3.5 h-3.5 text-blue-400" />
                {@challenge.duration_days}d
              </span>
            <% end %>
            <span class="flex items-center gap-1 text-xs text-slate-500 font-semibold">
              <.icon name="hero-user-group" class="w-3.5 h-3.5 text-indigo-400" />
              {@total_started} started
            </span>
            <span class={[
              "flex items-center gap-1 text-xs font-semibold",
              if(@has_completions, do: "text-green-600", else: "text-slate-400")
            ]}>
              <.icon
                name="hero-trophy"
                class={[
                  "w-3.5 h-3.5",
                  if(@has_completions, do: "text-green-500", else: "text-slate-300")
                ]}
              />
              <%= if @has_completions do %>
                {trunc(@success_rate)}%
              <% else %>
                —
              <% end %>
            </span>
          </div>
        </div>
      </HeadsUpWeb.Components.UI.Card.card>
    </.link>
    """
  end
end
