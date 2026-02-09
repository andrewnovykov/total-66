defmodule HeadsUpWeb.ConnectionsLive.Index do
  use HeadsUpWeb, :live_view

  alias HeadsUp.Accounts

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    if current_user do
      {:ok, load_connections(socket, current_user.id)}
    else
      {:ok, push_navigate(socket, to: "/users/log_in")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    tab = Map.get(params, "tab", "following")
    {:noreply, assign(socket, :active_tab, tab)}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, push_patch(socket, to: ~p"/connections?tab=#{tab}")}
  end

  @impl true
  def handle_event("unfollow_user", %{"user_id" => user_id}, socket) do
    current_user_id = socket.assigns.current_user.id
    user_id = String.to_integer(user_id)

    case Accounts.unfollow_user(current_user_id, user_id) do
      {:ok, _} ->
        socket = load_connections(socket, current_user_id)
        {:noreply, put_flash(socket, :info, "Successfully unfollowed user")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to unfollow user")}
    end
  end

  @impl true
  def handle_event("remove_follower", %{"user_id" => user_id}, socket) do
    current_user_id = socket.assigns.current_user.id
    user_id = String.to_integer(user_id)

    case Accounts.remove_follower(current_user_id, user_id) do
      {:ok, _} ->
        socket = load_connections(socket, current_user_id)
        {:noreply, put_flash(socket, :info, "Successfully removed follower")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to remove follower")}
    end
  end

  @impl true
  def handle_event("accept_friend_request", %{"user_id" => user_id}, socket) do
    current_user_id = socket.assigns.current_user.id
    user_id = String.to_integer(user_id)

    case Accounts.accept_friend_request(current_user_id, user_id) do
      {:ok, _} ->
        socket = load_connections(socket, current_user_id)
        {:noreply, put_flash(socket, :info, "Friend request accepted")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to accept friend request")}
    end
  end

  @impl true
  def handle_event("decline_friend_request", %{"user_id" => user_id}, socket) do
    current_user_id = socket.assigns.current_user.id
    user_id = String.to_integer(user_id)

    case Accounts.decline_friend_request(current_user_id, user_id) do
      {:ok, _} ->
        socket = load_connections(socket, current_user_id)
        {:noreply, put_flash(socket, :info, "Friend request declined")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to decline friend request")}
    end
  end

  @impl true
  def handle_event("cancel_friend_request", %{"user_id" => user_id}, socket) do
    current_user_id = socket.assigns.current_user.id
    user_id = String.to_integer(user_id)

    case Accounts.cancel_friend_request(current_user_id, user_id) do
      {:ok, _} ->
        socket = load_connections(socket, current_user_id)
        {:noreply, put_flash(socket, :info, "Friend request cancelled")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to cancel friend request")}
    end
  end

  @impl true
  def handle_event("remove_friend", %{"user_id" => user_id}, socket) do
    current_user_id = socket.assigns.current_user.id
    user_id = String.to_integer(user_id)

    case Accounts.remove_friend(current_user_id, user_id) do
      {:ok, _} ->
        socket = load_connections(socket, current_user_id)
        {:noreply, put_flash(socket, :info, "Friend removed successfully")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to remove friend")}
    end
  end

  defp load_connections(socket, user_id) do
    following = Accounts.list_following(user_id)
    followers = Accounts.list_followers(user_id)
    friends = Accounts.list_friends(user_id)
    incoming_requests = Accounts.list_friend_requests(user_id)
    sent_requests = Accounts.list_sent_friend_requests(user_id)

    socket
    |> assign(:following, following)
    |> assign(:followers, followers)
    |> assign(:friends, friends)
    |> assign(:incoming_requests, incoming_requests)
    |> assign(:sent_requests, sent_requests)
    |> assign(:following_count, length(following))
    |> assign(:followers_count, length(followers))
    |> assign(:friends_count, length(friends))
    |> assign(:requests_count, length(incoming_requests))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex gap-0 h-full">
      <%!-- Center Content --%>
      <div class="flex-grow min-w-0 p-5 sm:p-8 lg:p-10 overflow-y-auto custom-scrollbar">
        <%!-- Hero Banner --%>
        <div class="relative overflow-hidden bg-gradient-to-r from-blue-600 to-indigo-600 rounded-[40px] shadow-lg p-8 sm:p-10 lg:p-12 mb-8">
          <div class="relative z-10">
            <span class="inline-block px-4 py-1.5 bg-blue-500/50 text-blue-100 text-xs font-bold uppercase tracking-wider rounded-full mb-4">
              Network
            </span>
            <h1 class="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-white mb-3">
              Connections
            </h1>
            <p class="text-blue-100 text-lg max-w-xl">
              Manage your social connections and relationships
            </p>
          </div>
          <div class="absolute top-6 right-6 opacity-10">
            <.icon name="hero-user-group" class="w-32 h-32 text-white" />
          </div>
        </div>

        <%!-- Stats Cards --%>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
          <div class="bg-white rounded-[24px] shadow-sm p-5 text-center">
            <div class="w-10 h-10 rounded-xl bg-sky-50 flex items-center justify-center mx-auto mb-2">
              <.icon name="hero-eye" class="w-5 h-5 text-blue-600" />
            </div>
            <div class="text-2xl font-extrabold text-slate-900">{@following_count}</div>
            <div class="text-sm text-slate-500 font-medium">Following</div>
          </div>
          <div class="bg-white rounded-[24px] shadow-sm p-5 text-center">
            <div class="w-10 h-10 rounded-xl bg-green-50 flex items-center justify-center mx-auto mb-2">
              <.icon name="hero-users" class="w-5 h-5 text-green-600" />
            </div>
            <div class="text-2xl font-extrabold text-slate-900">{@followers_count}</div>
            <div class="text-sm text-slate-500 font-medium">Followers</div>
          </div>
          <div class="bg-white rounded-[24px] shadow-sm p-5 text-center">
            <div class="w-10 h-10 rounded-xl bg-indigo-50 flex items-center justify-center mx-auto mb-2">
              <.icon name="hero-heart" class="w-5 h-5 text-indigo-600" />
            </div>
            <div class="text-2xl font-extrabold text-slate-900">{@friends_count}</div>
            <div class="text-sm text-slate-500 font-medium">Friends</div>
          </div>
          <div class="bg-white rounded-[24px] shadow-sm p-5 text-center">
            <div class="w-10 h-10 rounded-xl bg-amber-50 flex items-center justify-center mx-auto mb-2">
              <.icon name="hero-inbox-arrow-down" class="w-5 h-5 text-amber-600" />
            </div>
            <div class="text-2xl font-extrabold text-slate-900">{@requests_count}</div>
            <div class="text-sm text-slate-500 font-medium">Requests</div>
          </div>
        </div>

        <%!-- Tab Navigation --%>
        <div class="flex flex-wrap gap-3 mb-8">
          <button
            phx-click="switch_tab"
            phx-value-tab="following"
            class={[
              "px-6 py-2.5 rounded-xl text-sm font-bold transition-all border-b-2",
              if(@active_tab == "following",
                do: "bg-slate-900 text-white border-blue-500 shadow-sm",
                else: "bg-white text-slate-500 border-transparent shadow-sm hover:bg-slate-50"
              )
            ]}
          >
            Following ({@following_count})
          </button>
          <button
            phx-click="switch_tab"
            phx-value-tab="followers"
            class={[
              "px-6 py-2.5 rounded-xl text-sm font-bold transition-all border-b-2",
              if(@active_tab == "followers",
                do: "bg-slate-900 text-white border-blue-500 shadow-sm",
                else: "bg-white text-slate-500 border-transparent shadow-sm hover:bg-slate-50"
              )
            ]}
          >
            Followers ({@followers_count})
          </button>
          <button
            phx-click="switch_tab"
            phx-value-tab="friends"
            class={[
              "px-6 py-2.5 rounded-xl text-sm font-bold transition-all border-b-2",
              if(@active_tab == "friends",
                do: "bg-slate-900 text-white border-blue-500 shadow-sm",
                else: "bg-white text-slate-500 border-transparent shadow-sm hover:bg-slate-50"
              )
            ]}
          >
            Friends ({@friends_count})
          </button>
          <button
            phx-click="switch_tab"
            phx-value-tab="requests"
            class={[
              "px-6 py-2.5 rounded-xl text-sm font-bold transition-all border-b-2",
              if(@active_tab == "requests",
                do: "bg-slate-900 text-white border-blue-500 shadow-sm",
                else: "bg-white text-slate-500 border-transparent shadow-sm hover:bg-slate-50"
              )
            ]}
          >
            Requests ({@requests_count})
          </button>
        </div>

        <%!-- Tab Content --%>
        <%= case @active_tab do %>
          <% "following" -> %>
            <.following_tab users={@following} />
          <% "followers" -> %>
            <.followers_tab users={@followers} />
          <% "friends" -> %>
            <.friends_tab users={@friends} />
          <% "requests" -> %>
            <.requests_tab incoming={@incoming_requests} sent={@sent_requests} />
        <% end %>
      </div>

      <%!-- Right Sidebar (Desktop Only) --%>
      <div class="hidden xl:flex flex-col w-[420px] flex-shrink-0 bg-white border-l border-slate-100 p-8 overflow-y-auto custom-scrollbar gap-10">
        <%!-- Network Overview --%>
        <div>
          <h3 class="text-lg font-extrabold text-slate-900 mb-4">Network Overview</h3>
          <div class="space-y-3">
            <div class="flex items-center justify-between p-4 bg-slate-50 rounded-2xl">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-xl bg-sky-50 flex items-center justify-center">
                  <.icon name="hero-eye" class="w-5 h-5 text-blue-600" />
                </div>
                <div>
                  <p class="text-sm font-bold text-slate-900">Following</p>
                  <p class="text-xs text-slate-500">People you follow</p>
                </div>
              </div>
              <span class="text-xl font-extrabold text-slate-900">{@following_count}</span>
            </div>
            <div class="flex items-center justify-between p-4 bg-slate-50 rounded-2xl">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-xl bg-green-50 flex items-center justify-center">
                  <.icon name="hero-users" class="w-5 h-5 text-green-600" />
                </div>
                <div>
                  <p class="text-sm font-bold text-slate-900">Followers</p>
                  <p class="text-xs text-slate-500">People following you</p>
                </div>
              </div>
              <span class="text-xl font-extrabold text-slate-900">{@followers_count}</span>
            </div>
            <div class="flex items-center justify-between p-4 bg-slate-50 rounded-2xl">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-xl bg-indigo-50 flex items-center justify-center">
                  <.icon name="hero-heart" class="w-5 h-5 text-indigo-600" />
                </div>
                <div>
                  <p class="text-sm font-bold text-slate-900">Friends</p>
                  <p class="text-xs text-slate-500">Mutual connections</p>
                </div>
              </div>
              <span class="text-xl font-extrabold text-slate-900">{@friends_count}</span>
            </div>
          </div>
        </div>

        <%!-- Quick Links --%>
        <div>
          <h3 class="text-lg font-extrabold text-slate-900 mb-4">Quick Links</h3>
          <div class="space-y-3">
            <.link
              navigate={~p"/people"}
              class="flex items-center gap-3 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors"
            >
              <div class="w-10 h-10 rounded-xl bg-sky-50 flex items-center justify-center">
                <.icon name="hero-magnifying-glass" class="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <p class="text-sm font-bold text-slate-900">Find Members</p>
                <p class="text-xs text-slate-500">Discover new connections</p>
              </div>
              <.icon name="hero-chevron-right" class="w-4 h-4 text-slate-400 ml-auto" />
            </.link>
            <.link
              navigate={~p"/my-challenges"}
              class="flex items-center gap-3 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors"
            >
              <div class="w-10 h-10 rounded-xl bg-indigo-50 flex items-center justify-center">
                <.icon name="hero-bolt" class="w-5 h-5 text-indigo-600" />
              </div>
              <div>
                <p class="text-sm font-bold text-slate-900">My Challenges</p>
                <p class="text-xs text-slate-500">View your challenges</p>
              </div>
              <.icon name="hero-chevron-right" class="w-4 h-4 text-slate-400 ml-auto" />
            </.link>
          </div>
        </div>

        <%!-- Grow Network Promo --%>
        <div class="relative overflow-hidden bg-gradient-to-br from-blue-600 to-indigo-700 rounded-[32px] p-8">
          <div class="relative z-10">
            <div class="w-14 h-14 rounded-2xl bg-white/20 flex items-center justify-center mb-4">
              <.icon name="hero-user-plus" class="w-7 h-7 text-white" />
            </div>
            <h4 class="text-xl font-extrabold text-white mb-2">Grow Your Network</h4>
            <p class="text-blue-100 text-sm mb-6">
              Connect with goal-setters and build your community
            </p>
            <.link
              navigate={~p"/people"}
              class="inline-flex items-center gap-2 bg-white text-blue-600 px-6 py-3 rounded-xl font-bold text-sm hover:scale-105 transition-transform"
            >
              <.icon name="hero-magnifying-glass" class="w-4 h-4" /> Browse Members
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

  # -- Tab Components --

  defp following_tab(assigns) do
    ~H"""
    <div class="space-y-4">
      <%= if Enum.empty?(@users) do %>
        <div class="bg-white rounded-[40px] shadow-sm p-10 text-center">
          <div class="w-16 h-16 rounded-2xl bg-sky-50 flex items-center justify-center mx-auto mb-4">
            <.icon name="hero-eye" class="w-8 h-8 text-blue-400" />
          </div>
          <div class="text-lg font-extrabold text-slate-900 mb-2">
            You're not following anyone yet
          </div>
          <p class="text-sm text-slate-500 max-w-sm mx-auto">
            Start following people to see their goal updates in your feed
          </p>
          <.link
            navigate={~p"/people"}
            class="inline-flex items-center gap-2 mt-6 bg-gradient-to-r from-blue-500 to-indigo-600 text-white px-6 py-3 rounded-xl font-bold text-sm hover:scale-105 transition-transform"
          >
            <.icon name="hero-magnifying-glass" class="w-4 h-4" /> Find Members
          </.link>
        </div>
      <% else %>
        <%= for user <- @users do %>
          <.user_card user={user} tab="following" />
        <% end %>
      <% end %>
    </div>
    """
  end

  defp followers_tab(assigns) do
    ~H"""
    <div class="space-y-4">
      <%= if Enum.empty?(@users) do %>
        <div class="bg-white rounded-[40px] shadow-sm p-10 text-center">
          <div class="w-16 h-16 rounded-2xl bg-green-50 flex items-center justify-center mx-auto mb-4">
            <.icon name="hero-users" class="w-8 h-8 text-green-400" />
          </div>
          <div class="text-lg font-extrabold text-slate-900 mb-2">No followers yet</div>
          <p class="text-sm text-slate-500 max-w-sm mx-auto">
            Share your goals and connect with people to gain followers
          </p>
        </div>
      <% else %>
        <%= for user <- @users do %>
          <.user_card user={user} tab="followers" />
        <% end %>
      <% end %>
    </div>
    """
  end

  defp friends_tab(assigns) do
    ~H"""
    <div class="space-y-4">
      <%= if Enum.empty?(@users) do %>
        <div class="bg-white rounded-[40px] shadow-sm p-10 text-center">
          <div class="w-16 h-16 rounded-2xl bg-indigo-50 flex items-center justify-center mx-auto mb-4">
            <.icon name="hero-heart" class="w-8 h-8 text-indigo-400" />
          </div>
          <div class="text-lg font-extrabold text-slate-900 mb-2">No friends yet</div>
          <p class="text-sm text-slate-500 max-w-sm mx-auto">
            Send friend requests to build your network
          </p>
        </div>
      <% else %>
        <%= for user <- @users do %>
          <.user_card user={user} tab="friends" />
        <% end %>
      <% end %>
    </div>
    """
  end

  defp requests_tab(assigns) do
    ~H"""
    <div class="space-y-8">
      <%!-- Incoming Friend Requests --%>
      <div>
        <h2 class="text-xl font-extrabold text-slate-900 mb-4 flex items-center gap-2">
          <.icon name="hero-inbox-arrow-down" class="w-5 h-5 text-blue-600" />
          Incoming Friend Requests
        </h2>
        <%= if Enum.empty?(@incoming) do %>
          <div class="bg-white rounded-[40px] shadow-sm p-10 text-center">
            <div class="w-16 h-16 rounded-2xl bg-slate-50 flex items-center justify-center mx-auto mb-4">
              <.icon name="hero-inbox" class="w-8 h-8 text-slate-400" />
            </div>
            <div class="text-lg font-extrabold text-slate-900 mb-2">No pending friend requests</div>
            <p class="text-sm text-slate-500 max-w-sm mx-auto">Friend requests will appear here</p>
          </div>
        <% else %>
          <div class="space-y-4">
            <%= for request <- @incoming do %>
              <div class="bg-blue-50 rounded-[32px] p-6 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                <div class="flex items-center gap-4">
                  <HeadsUpWeb.Components.UI.Avatar.avatar
                    name={request.user.name || request.user.user_name || "U"}
                    src={request.user.image_path}
                    size={:lg}
                    rounded={:xl}
                  />
                  <div>
                    <h3 class="font-extrabold text-slate-900">{request.user.name}</h3>
                    <p class="text-sm text-slate-500">@{request.user.user_name}</p>
                    <%= if request.user.bio do %>
                      <p class="text-sm text-slate-600 mt-1 line-clamp-1">{request.user.bio}</p>
                    <% end %>
                  </div>
                </div>
                <div class="flex gap-2 w-full sm:w-auto">
                  <button
                    phx-click="accept_friend_request"
                    phx-value-user_id={request.user.id}
                    class="flex-1 sm:flex-initial inline-flex items-center justify-center gap-2 bg-gradient-to-r from-green-500 to-emerald-600 text-white px-5 py-2.5 rounded-xl font-bold text-sm hover:scale-105 transition-transform"
                  >
                    <.icon name="hero-check" class="w-4 h-4" /> Accept
                  </button>
                  <button
                    phx-click="decline_friend_request"
                    phx-value-user_id={request.user.id}
                    class="flex-1 sm:flex-initial inline-flex items-center justify-center gap-2 bg-white text-red-600 px-5 py-2.5 rounded-xl font-bold text-sm border border-red-200 hover:bg-red-50 transition-colors"
                  >
                    <.icon name="hero-x-mark" class="w-4 h-4" /> Decline
                  </button>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>

      <%!-- Sent Friend Requests --%>
      <div>
        <h2 class="text-xl font-extrabold text-slate-900 mb-4 flex items-center gap-2">
          <.icon name="hero-paper-airplane" class="w-5 h-5 text-amber-600" /> Sent Friend Requests
        </h2>
        <%= if Enum.empty?(@sent) do %>
          <div class="bg-white rounded-[40px] shadow-sm p-10 text-center">
            <div class="w-16 h-16 rounded-2xl bg-amber-50 flex items-center justify-center mx-auto mb-4">
              <.icon name="hero-paper-airplane" class="w-8 h-8 text-amber-400" />
            </div>
            <div class="text-lg font-extrabold text-slate-900 mb-2">No pending sent requests</div>
            <p class="text-sm text-slate-500 max-w-sm mx-auto">
              Requests you've sent will appear here
            </p>
          </div>
        <% else %>
          <div class="space-y-4">
            <%= for request <- @sent do %>
              <div class="bg-white rounded-[32px] shadow-sm p-6 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 border border-amber-100">
                <div class="flex items-center gap-4">
                  <HeadsUpWeb.Components.UI.Avatar.avatar
                    name={request.friend.name || request.friend.user_name || "U"}
                    src={request.friend.image_path}
                    size={:lg}
                    rounded={:xl}
                  />
                  <div>
                    <h3 class="font-extrabold text-slate-900">{request.friend.name}</h3>
                    <p class="text-sm text-slate-500">@{request.friend.user_name}</p>
                    <%= if request.friend.bio do %>
                      <p class="text-sm text-slate-600 mt-1 line-clamp-1">{request.friend.bio}</p>
                    <% end %>
                    <span class="inline-flex items-center gap-1 mt-1 text-xs font-medium text-amber-600 bg-amber-50 px-2.5 py-1 rounded-full">
                      <.icon name="hero-clock" class="w-3 h-3" /> Pending approval
                    </span>
                  </div>
                </div>
                <button
                  phx-click="cancel_friend_request"
                  phx-value-user_id={request.friend.id}
                  data-confirm="Are you sure you want to cancel this friend request?"
                  class="inline-flex items-center justify-center gap-2 bg-white text-red-600 px-5 py-2.5 rounded-xl font-bold text-sm border border-red-200 hover:bg-red-50 transition-colors"
                >
                  <.icon name="hero-x-mark" class="w-4 h-4" /> Cancel Request
                </button>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # -- User Card Component --

  defp user_card(assigns) do
    ~H"""
    <div class="bg-white rounded-[32px] shadow-sm p-6 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 hover:shadow-md transition-shadow">
      <div class="flex items-center gap-4">
        <HeadsUpWeb.Components.UI.Avatar.avatar
          name={@user.name || @user.user_name || "U"}
          src={@user.image_path}
          size={:lg}
          rounded={:xl}
        />
        <div>
          <h3 class="font-extrabold text-slate-900">{@user.name}</h3>
          <p class="text-sm text-slate-500">@{@user.user_name}</p>
          <%= if @user.bio do %>
            <p class="text-sm text-slate-600 mt-1 line-clamp-1">{@user.bio}</p>
          <% end %>
        </div>
      </div>
      <div class="flex gap-2 w-full sm:w-auto">
        <.link
          navigate={~p"/people/#{@user.user_name}"}
          class="flex-1 sm:flex-initial inline-flex items-center justify-center gap-2 bg-slate-100 text-slate-700 px-5 py-2.5 rounded-xl font-bold text-sm hover:bg-slate-200 transition-colors"
        >
          <.icon name="hero-user" class="w-4 h-4" /> View Profile
        </.link>
        <%= case @tab do %>
          <% "following" -> %>
            <button
              phx-click="unfollow_user"
              phx-value-user_id={@user.id}
              data-confirm="Are you sure you want to unfollow this user?"
              class="flex-1 sm:flex-initial inline-flex items-center justify-center gap-2 bg-white text-red-600 px-5 py-2.5 rounded-xl font-bold text-sm border border-red-200 hover:bg-red-50 transition-colors"
            >
              <.icon name="hero-user-minus" class="w-4 h-4" /> Unfollow
            </button>
          <% "followers" -> %>
            <button
              phx-click="remove_follower"
              phx-value-user_id={@user.id}
              data-confirm="Are you sure you want to remove this follower?"
              class="flex-1 sm:flex-initial inline-flex items-center justify-center gap-2 bg-white text-red-600 px-5 py-2.5 rounded-xl font-bold text-sm border border-red-200 hover:bg-red-50 transition-colors"
            >
              <.icon name="hero-x-mark" class="w-4 h-4" /> Remove
            </button>
          <% "friends" -> %>
            <button
              phx-click="remove_friend"
              phx-value-user_id={@user.id}
              data-confirm="Are you sure you want to remove this friend?"
              class="flex-1 sm:flex-initial inline-flex items-center justify-center gap-2 bg-white text-red-600 px-5 py-2.5 rounded-xl font-bold text-sm border border-red-200 hover:bg-red-50 transition-colors"
            >
              <.icon name="hero-user-minus" class="w-4 h-4" /> Remove Friend
            </button>
          <% _ -> %>
        <% end %>
      </div>
    </div>
    """
  end

  defp user_avatar_bg_class(name) do
    colors = [
      "bg-red-500",
      "bg-blue-500",
      "bg-green-500",
      "bg-yellow-500",
      "bg-purple-500",
      "bg-pink-500",
      "bg-indigo-500",
      "bg-orange-500"
    ]

    hash = :erlang.phash2(name || "")
    Enum.at(colors, rem(hash, length(colors)))
  end
end
