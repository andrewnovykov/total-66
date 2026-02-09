defmodule HeadsUpWeb.UsersLive.Index do
  use HeadsUpWeb, :live_view
  alias HeadsUp.{Accounts, Repo}
  import Ecto.Query

  def mount(_params, _session, socket) do
    users = Accounts.list_users() |> add_challenge_counts()

    socket =
      socket
      |> assign(:users, users)
      |> assign(:filtered_users, users)
      |> assign(:search_query, "")
      |> assign(:filter_type, "all")

    {:ok, socket}
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

  defp filter_users(users, query, _type) when query == "", do: users

  defp filter_users(users, query, _type) do
    search_term = String.downcase(query)

    Enum.filter(users, fn user ->
      name_match = String.contains?(String.downcase(user.name || ""), search_term)
      username_match = String.contains?(String.downcase(user.user_name || ""), search_term)
      bio_match = String.contains?(String.downcase(user.bio || ""), search_term)

      name_match || username_match || bio_match
    end)
  end

  def render(assigns) do
    ~H"""
    <div class="flex gap-0 h-full">
      <%!-- Center Content --%>
      <div class="flex-grow min-w-0 p-5 sm:p-8 lg:p-10 overflow-y-auto custom-scrollbar">
        <%!-- Hero Banner --%>
        <div class="relative overflow-hidden bg-gradient-to-r from-blue-600 to-indigo-600 rounded-[40px] shadow-lg p-8 sm:p-10 lg:p-12 mb-8">
          <div class="relative z-10">
            <span class="inline-block px-4 py-1.5 bg-blue-500/50 text-blue-100 text-xs font-bold uppercase tracking-wider rounded-full mb-4">
              Community
            </span>
            <h1 class="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-white mb-3">
              Members
            </h1>
            <p class="text-blue-100 text-lg max-w-xl mb-6">
              Find members to follow and collaborate with
            </p>

            <%!-- Search Bar in Hero --%>
            <.form for={%{}} phx-change="search" class="max-w-lg">
              <div class="relative">
                <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                  <.icon name="hero-magnifying-glass" class="w-5 h-5 text-slate-400" />
                </div>
                <input
                  name="search[query]"
                  placeholder="Search by name, username, or bio..."
                  class="w-full bg-white/95 backdrop-blur-sm text-slate-900 placeholder:text-slate-400 pl-12 pr-4 py-4 rounded-2xl border-0 focus:ring-2 focus:ring-white/50 text-base font-medium shadow-lg"
                  value={@search_query}
                />
              </div>
            </.form>
          </div>
          <div class="absolute top-6 right-6 opacity-10">
            <.icon name="hero-users" class="w-32 h-32 text-white" />
          </div>
        </div>

        <%!-- Filter Pills + Results Header --%>
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
          <div>
            <h2 class="text-2xl font-extrabold text-slate-900">
              <%= if @search_query != "" do %>
                Search Results
              <% else %>
                Top Goal Setters
              <% end %>
            </h2>
            <p class="text-slate-400 text-sm mt-1">{length(@filtered_users)} members</p>
          </div>
          <div class="flex gap-3 flex-wrap">
            <button
              phx-click="filter"
              phx-value-type="all"
              class={[
                "px-6 py-2.5 rounded-xl text-sm font-bold transition-all",
                if(@filter_type == "all",
                  do: "bg-slate-900 text-white shadow-sm",
                  else: "bg-white text-slate-500 shadow-sm hover:bg-slate-50"
                )
              ]}
            >
              All
            </button>
            <button
              phx-click="filter"
              phx-value-type="following"
              class={[
                "px-6 py-2.5 rounded-xl text-sm font-bold transition-all",
                if(@filter_type == "following",
                  do: "bg-slate-900 text-white shadow-sm",
                  else: "bg-white text-slate-500 shadow-sm hover:bg-slate-50"
                )
              ]}
            >
              Following
            </button>
            <button
              phx-click="filter"
              phx-value-type="recommended"
              class={[
                "px-6 py-2.5 rounded-xl text-sm font-bold transition-all",
                if(@filter_type == "recommended",
                  do: "bg-slate-900 text-white shadow-sm",
                  else: "bg-white text-slate-500 shadow-sm hover:bg-slate-50"
                )
              ]}
            >
              Recommended
            </button>
          </div>
        </div>

        <%!-- Members Feed --%>
        <%= if Enum.empty?(@filtered_users) do %>
          <div class="bg-white rounded-[40px] shadow-sm p-10 text-center">
            <div class="w-16 h-16 rounded-2xl bg-slate-50 flex items-center justify-center mx-auto mb-4">
              <.icon name="hero-users" class="w-8 h-8 text-slate-400" />
            </div>
            <div class="text-lg font-extrabold text-slate-900 mb-2">
              <%= if @search_query != "" do %>
                No members found matching "{@search_query}"
              <% else %>
                No members to display
              <% end %>
            </div>
            <p class="text-sm text-slate-500 max-w-sm mx-auto">
              Try adjusting your search or filters
            </p>
          </div>
        <% else %>
          <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4">
            <%= for user <- @filtered_users do %>
              <.link
                navigate={~p"/people/#{user.user_name || "user-#{user.id}"}"}
                class="block bg-white rounded-3xl shadow-sm p-5 hover:shadow-md transition-all group text-center"
              >
                <%!-- Avatar / Privacy Icon --%>
                <div class="flex justify-center mb-3">
                  <%= if user.privacy == "private" do %>
                    <div class="w-16 h-16 rounded-full bg-slate-100 flex items-center justify-center">
                      <.icon name="hero-lock-closed-solid" class="w-7 h-7 text-slate-400" />
                    </div>
                  <% else %>
                    <HeadsUpWeb.Components.UI.Avatar.avatar
                      name={user.name || user.user_name || "U"}
                      src={user.image_path}
                      size={:xl}
                    />
                  <% end %>
                </div>

                <%!-- Name + Badge --%>
                <%= if user.privacy == "private" do %>
                  <h3 class="text-sm font-extrabold text-slate-400 truncate mb-1">Private</h3>
                  <span class="inline-flex items-center gap-1 px-2 py-0.5 bg-slate-100 text-slate-500 text-[10px] font-bold rounded-full">
                    <.icon name="hero-lock-closed" class="w-3 h-3" /> Private
                  </span>
                <% else %>
                  <h3 class="text-sm font-extrabold text-slate-900 truncate group-hover:text-blue-600 transition-colors mb-0.5">
                    {user.name || user.user_name || "Anonymous"}
                  </h3>
                  <p class="text-xs text-slate-400 truncate mb-2">@{user.user_name || "unknown"}</p>

                  <%!-- Privacy / Level Badge --%>
                  <%= if user.privacy == "friends_only" do %>
                    <span class="inline-flex items-center gap-1 px-2 py-0.5 bg-amber-50 text-amber-600 text-[10px] font-bold rounded-full mb-2">
                      <.icon name="hero-user-group" class="w-3 h-3" /> Friends Only
                    </span>
                  <% else %>
                    <%= if (user.level || 1) >= 5 do %>
                      <span class="inline-flex items-center gap-1 px-2 py-0.5 bg-amber-50 text-amber-600 text-[10px] font-bold rounded-full mb-2">
                        <.icon name="hero-star-solid" class="w-3 h-3" /> Lvl {user.level}
                      </span>
                    <% end %>
                  <% end %>

                  <%!-- Stats Row --%>
                  <div class="flex items-center justify-center gap-3 text-xs">
                    <span class="flex items-center gap-1 text-slate-500 font-bold">
                      <.icon name="hero-flag" class="w-3.5 h-3.5 text-blue-500" />
                      {user.goal_amount || 0}
                    </span>
                    <span class="flex items-center gap-1 text-slate-500 font-bold">
                      <.icon name="hero-trophy" class="w-3.5 h-3.5 text-indigo-500" />
                      {Map.get(user, :challenge_count, 0)}
                    </span>
                    <span class="flex items-center gap-1 text-slate-500 font-bold">
                      <.icon name="hero-arrow-trending-up" class="w-3.5 h-3.5 text-green-500" />
                      Lvl {user.level || 1}
                    </span>
                  </div>
                <% end %>
              </.link>
            <% end %>
          </div>
        <% end %>
      </div>

      <%!-- Right Sidebar (Desktop Only) --%>
      <div class="hidden xl:flex flex-col w-[420px] flex-shrink-0 bg-white border-l border-slate-100 p-8 overflow-y-auto custom-scrollbar gap-10">
        <%!-- Community Stats --%>
        <div>
          <h3 class="text-lg font-extrabold text-slate-900 mb-4">Community Stats</h3>
          <div class="space-y-3">
            <div class="flex items-center justify-between p-4 bg-slate-50 rounded-2xl">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-xl bg-sky-50 flex items-center justify-center">
                  <.icon name="hero-users" class="w-5 h-5 text-blue-600" />
                </div>
                <div>
                  <p class="text-sm font-bold text-slate-900">Total Members</p>
                  <p class="text-xs text-slate-500">Active community</p>
                </div>
              </div>
              <span class="text-xl font-extrabold text-slate-900">{length(@users)}</span>
            </div>
            <div class="flex items-center justify-between p-4 bg-slate-50 rounded-2xl">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-xl bg-green-50 flex items-center justify-center">
                  <.icon name="hero-flag" class="w-5 h-5 text-green-600" />
                </div>
                <div>
                  <p class="text-sm font-bold text-slate-900">Goals Created</p>
                  <p class="text-xs text-slate-500">Across all members</p>
                </div>
              </div>
              <span class="text-xl font-extrabold text-slate-900">
                {Enum.reduce(@users, 0, fn u, acc -> acc + (u.goal_amount || 0) end)}
              </span>
            </div>
          </div>
        </div>

        <%!-- Quick Links --%>
        <div>
          <h3 class="text-lg font-extrabold text-slate-900 mb-4">Quick Links</h3>
          <div class="space-y-3">
            <.link
              navigate={~p"/connections"}
              class="flex items-center gap-3 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors"
            >
              <div class="w-10 h-10 rounded-xl bg-indigo-50 flex items-center justify-center">
                <.icon name="hero-link" class="w-5 h-5 text-indigo-600" />
              </div>
              <div>
                <p class="text-sm font-bold text-slate-900">My Connections</p>
                <p class="text-xs text-slate-500">Manage your network</p>
              </div>
              <.icon name="hero-chevron-right" class="w-4 h-4 text-slate-400 ml-auto" />
            </.link>
            <.link
              navigate={~p"/all-goals"}
              class="flex items-center gap-3 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors"
            >
              <div class="w-10 h-10 rounded-xl bg-green-50 flex items-center justify-center">
                <.icon name="hero-flag" class="w-5 h-5 text-green-600" />
              </div>
              <div>
                <p class="text-sm font-bold text-slate-900">Browse Goals</p>
                <p class="text-xs text-slate-500">Explore all goals</p>
              </div>
              <.icon name="hero-chevron-right" class="w-4 h-4 text-slate-400 ml-auto" />
            </.link>
          </div>
        </div>

        <%!-- Connect Promo --%>
        <div class="relative overflow-hidden bg-gradient-to-br from-blue-600 to-indigo-700 rounded-[32px] p-8">
          <div class="relative z-10">
            <div class="w-14 h-14 rounded-2xl bg-white/20 flex items-center justify-center mb-4">
              <.icon name="hero-user-plus" class="w-7 h-7 text-white" />
            </div>
            <h4 class="text-xl font-extrabold text-white mb-2">Build Your Network</h4>
            <p class="text-blue-100 text-sm mb-6">
              Follow members, send friend requests, and grow together
            </p>
            <.link
              navigate={~p"/connections"}
              class="inline-flex items-center gap-2 bg-white text-blue-600 px-6 py-3 rounded-xl font-bold text-sm hover:scale-105 transition-transform"
            >
              <.icon name="hero-link" class="w-4 h-4" /> My Connections
            </.link>
          </div>
          <div class="absolute -bottom-4 -right-4 opacity-10">
            <.icon name="hero-user-group" class="w-32 h-32 text-white" />
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp add_challenge_counts(users) do
    user_ids = Enum.map(users, & &1.id)

    counts =
      from(cp in HeadsUp.Challenges.ChallengeParticipant,
        where: cp.user_id in ^user_ids,
        group_by: cp.user_id,
        select: {cp.user_id, count(cp.id)}
      )
      |> Repo.all()
      |> Map.new()

    Enum.map(users, fn user ->
      Map.put(user, :challenge_count, Map.get(counts, user.id, 0))
    end)
  end

  defp user_avatar_bg_class(name) do
    colors = [
      "bg-gradient-to-br from-blue-400 to-indigo-500",
      "bg-gradient-to-br from-green-400 to-emerald-500",
      "bg-gradient-to-br from-purple-400 to-violet-500",
      "bg-gradient-to-br from-amber-400 to-orange-500",
      "bg-gradient-to-br from-pink-400 to-rose-500",
      "bg-gradient-to-br from-cyan-400 to-blue-500",
      "bg-gradient-to-br from-red-400 to-pink-500",
      "bg-gradient-to-br from-indigo-400 to-purple-500"
    ]

    hash = :erlang.phash2(name || "")
    Enum.at(colors, rem(hash, length(colors)))
  end
end
