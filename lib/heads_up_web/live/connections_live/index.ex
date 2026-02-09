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
            Connections
          </h1>
          <p class="text-t66-text-muted text-[0.9rem] mt-1.5">
            Manage your social connections and relationships
          </p>
        </div>

        <%!-- Stats Row --%>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-3 mb-8">
          <div class="bg-t66-card border border-white/[0.06] rounded-2xl p-5 text-center">
            <div class="font-['Bebas_Neue'] text-[2rem] leading-none text-t66-accent">{@following_count}</div>
            <div class="text-[0.6rem] uppercase tracking-[2px] text-t66-text-muted mt-1">Following</div>
          </div>
          <div class="bg-t66-card border border-white/[0.06] rounded-2xl p-5 text-center">
            <div class="font-['Bebas_Neue'] text-[2rem] leading-none text-[#22c55e]">{@followers_count}</div>
            <div class="text-[0.6rem] uppercase tracking-[2px] text-t66-text-muted mt-1">Followers</div>
          </div>
          <div class="bg-t66-card border border-white/[0.06] rounded-2xl p-5 text-center">
            <div class="font-['Bebas_Neue'] text-[2rem] leading-none text-[#ffc642]">{@friends_count}</div>
            <div class="text-[0.6rem] uppercase tracking-[2px] text-t66-text-muted mt-1">Friends</div>
          </div>
          <div class="bg-t66-card border border-white/[0.06] rounded-2xl p-5 text-center">
            <div class="font-['Bebas_Neue'] text-[2rem] leading-none text-[#3b82f6]">{@requests_count}</div>
            <div class="text-[0.6rem] uppercase tracking-[2px] text-t66-text-muted mt-1">Requests</div>
          </div>
        </div>

        <%!-- Tab Navigation --%>
        <div class="flex flex-wrap gap-1.5 mb-6">
          <button
            phx-click="switch_tab"
            phx-value-tab="following"
            class={[
              "px-[18px] py-2 rounded-lg text-[0.78rem] font-semibold tracking-[0.5px] transition-all border",
              if(@active_tab == "following",
                do: "border-[#ff4d00] text-[#ff4d00] bg-[rgba(255,77,0,0.15)]",
                else: "border-white/[0.06] text-[#5a5754] hover:border-white/[0.12] hover:text-[#8a8680]"
              )
            ]}
          >
            Following ({@following_count})
          </button>
          <button
            phx-click="switch_tab"
            phx-value-tab="followers"
            class={[
              "px-[18px] py-2 rounded-lg text-[0.78rem] font-semibold tracking-[0.5px] transition-all border",
              if(@active_tab == "followers",
                do: "border-[#ff4d00] text-[#ff4d00] bg-[rgba(255,77,0,0.15)]",
                else: "border-white/[0.06] text-[#5a5754] hover:border-white/[0.12] hover:text-[#8a8680]"
              )
            ]}
          >
            Followers ({@followers_count})
          </button>
          <button
            phx-click="switch_tab"
            phx-value-tab="friends"
            class={[
              "px-[18px] py-2 rounded-lg text-[0.78rem] font-semibold tracking-[0.5px] transition-all border",
              if(@active_tab == "friends",
                do: "border-[#ff4d00] text-[#ff4d00] bg-[rgba(255,77,0,0.15)]",
                else: "border-white/[0.06] text-[#5a5754] hover:border-white/[0.12] hover:text-[#8a8680]"
              )
            ]}
          >
            Friends ({@friends_count})
          </button>
          <button
            phx-click="switch_tab"
            phx-value-tab="requests"
            class={[
              "px-[18px] py-2 rounded-lg text-[0.78rem] font-semibold tracking-[0.5px] transition-all border",
              if(@active_tab == "requests",
                do: "border-[#ff4d00] text-[#ff4d00] bg-[rgba(255,77,0,0.15)]",
                else: "border-white/[0.06] text-[#5a5754] hover:border-white/[0.12] hover:text-[#8a8680]"
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
    </div>
    """
  end

  # -- Tab Components --

  defp following_tab(assigns) do
    ~H"""
    <div class="flex flex-col gap-2">
      <%= if Enum.empty?(@users) do %>
        <div class="bg-t66-card border border-white/[0.06] rounded-2xl p-10 text-center">
          <div class="w-14 h-14 rounded-xl bg-[rgba(255,77,0,0.15)] flex items-center justify-center mx-auto mb-4">
            <.icon name="hero-eye" class="w-7 h-7 text-t66-accent" />
          </div>
          <div class="text-lg font-bold text-[#f0ece6] mb-2">
            You're not following anyone yet
          </div>
          <p class="text-sm text-t66-text-muted max-w-sm mx-auto">
            Start following people to see their updates in your feed
          </p>
          <.link
            navigate={~p"/people"}
            class="inline-flex items-center gap-2 mt-6 bg-t66-accent text-white px-6 py-3 rounded-xl font-bold text-sm hover:-translate-y-0.5 transition-transform shadow-[0_0_30px_rgba(255,77,0,0.2)]"
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
    <div class="flex flex-col gap-2">
      <%= if Enum.empty?(@users) do %>
        <div class="bg-t66-card border border-white/[0.06] rounded-2xl p-10 text-center">
          <div class="w-14 h-14 rounded-xl bg-[rgba(34,197,94,0.12)] flex items-center justify-center mx-auto mb-4">
            <.icon name="hero-users" class="w-7 h-7 text-[#22c55e]" />
          </div>
          <div class="text-lg font-bold text-[#f0ece6] mb-2">No followers yet</div>
          <p class="text-sm text-t66-text-muted max-w-sm mx-auto">
            Share your challenges and connect with people to gain followers
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
    <div class="flex flex-col gap-2">
      <%= if Enum.empty?(@users) do %>
        <div class="bg-t66-card border border-white/[0.06] rounded-2xl p-10 text-center">
          <div class="w-14 h-14 rounded-xl bg-[rgba(255,198,66,0.15)] flex items-center justify-center mx-auto mb-4">
            <.icon name="hero-heart" class="w-7 h-7 text-[#ffc642]" />
          </div>
          <div class="text-lg font-bold text-[#f0ece6] mb-2">No friends yet</div>
          <p class="text-sm text-t66-text-muted max-w-sm mx-auto">
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
        <h2 class="text-lg font-bold text-[#f0ece6] mb-4 flex items-center gap-2">
          <.icon name="hero-inbox-arrow-down" class="w-5 h-5 text-t66-accent" />
          Incoming Friend Requests
        </h2>
        <%= if Enum.empty?(@incoming) do %>
          <div class="bg-t66-card border border-white/[0.06] rounded-2xl p-10 text-center">
            <div class="w-14 h-14 rounded-xl bg-white/[0.04] flex items-center justify-center mx-auto mb-4">
              <.icon name="hero-inbox" class="w-7 h-7 text-t66-text-muted" />
            </div>
            <div class="text-lg font-bold text-[#f0ece6] mb-2">No pending friend requests</div>
            <p class="text-sm text-t66-text-muted max-w-sm mx-auto">Friend requests will appear here</p>
          </div>
        <% else %>
          <div class="flex flex-col gap-2">
            <%= for request <- @incoming do %>
              <div class="incoming-request bg-[rgba(255,77,0,0.06)] border border-[rgba(255,77,0,0.15)] rounded-2xl p-5 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                <div class="flex items-center gap-3.5">
                  <HeadsUpWeb.Components.UI.Avatar.avatar
                    name={request.user.name || request.user.user_name || "U"}
                    src={request.user.image_path}
                    size={:lg}
                    rounded={:xl}
                  />
                  <div>
                    <h3 class="font-bold text-[#f0ece6]">{request.user.name}</h3>
                    <p class="text-sm text-t66-text-muted">@{request.user.user_name}</p>
                    <%= if request.user.bio do %>
                      <p class="text-sm text-t66-text-secondary mt-1 line-clamp-1">{request.user.bio}</p>
                    <% end %>
                  </div>
                </div>
                <div class="flex gap-2 w-full sm:w-auto">
                  <button
                    phx-click="accept_friend_request"
                    phx-value-user_id={request.user.id}
                    class="flex-1 sm:flex-initial inline-flex items-center justify-center gap-2 bg-[#22c55e] text-white px-5 py-2.5 rounded-xl font-bold text-sm hover:-translate-y-0.5 transition-transform"
                  >
                    <.icon name="hero-check" class="w-4 h-4" /> Accept
                  </button>
                  <button
                    phx-click="decline_friend_request"
                    phx-value-user_id={request.user.id}
                    class="flex-1 sm:flex-initial inline-flex items-center justify-center gap-2 bg-transparent text-[#ef4444] px-5 py-2.5 rounded-xl font-bold text-sm border border-[rgba(239,68,68,0.3)] hover:bg-[rgba(239,68,68,0.12)] transition-colors"
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
        <h2 class="text-lg font-bold text-[#f0ece6] mb-4 flex items-center gap-2">
          <.icon name="hero-paper-airplane" class="w-5 h-5 text-[#ffc642]" /> Sent Friend Requests
        </h2>
        <%= if Enum.empty?(@sent) do %>
          <div class="bg-t66-card border border-white/[0.06] rounded-2xl p-10 text-center">
            <div class="w-14 h-14 rounded-xl bg-[rgba(255,198,66,0.15)] flex items-center justify-center mx-auto mb-4">
              <.icon name="hero-paper-airplane" class="w-7 h-7 text-[#ffc642]" />
            </div>
            <div class="text-lg font-bold text-[#f0ece6] mb-2">No pending sent requests</div>
            <p class="text-sm text-t66-text-muted max-w-sm mx-auto">
              Requests you've sent will appear here
            </p>
          </div>
        <% else %>
          <div class="flex flex-col gap-2">
            <%= for request <- @sent do %>
              <div class="bg-t66-card border border-white/[0.06] rounded-2xl p-5 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                <div class="flex items-center gap-3.5">
                  <HeadsUpWeb.Components.UI.Avatar.avatar
                    name={request.friend.name || request.friend.user_name || "U"}
                    src={request.friend.image_path}
                    size={:lg}
                    rounded={:xl}
                  />
                  <div>
                    <h3 class="font-bold text-[#f0ece6]">{request.friend.name}</h3>
                    <p class="text-sm text-t66-text-muted">@{request.friend.user_name}</p>
                    <%= if request.friend.bio do %>
                      <p class="text-sm text-t66-text-secondary mt-1 line-clamp-1">{request.friend.bio}</p>
                    <% end %>
                    <span class="inline-flex items-center gap-1 mt-1 text-xs font-medium text-[#ffc642] bg-[rgba(255,198,66,0.15)] px-2.5 py-1 rounded-full">
                      <.icon name="hero-clock" class="w-3 h-3" /> Pending approval
                    </span>
                  </div>
                </div>
                <button
                  phx-click="cancel_friend_request"
                  phx-value-user_id={request.friend.id}
                  data-confirm="Are you sure you want to cancel this friend request?"
                  class="inline-flex items-center justify-center gap-2 bg-transparent text-[#ef4444] px-5 py-2.5 rounded-xl font-bold text-sm border border-[rgba(239,68,68,0.3)] hover:bg-[rgba(239,68,68,0.12)] transition-colors"
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
    <div class="bg-t66-card border border-white/[0.06] rounded-2xl p-5 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 hover:border-white/[0.1] transition-colors">
      <div class="flex items-center gap-3.5">
        <HeadsUpWeb.Components.UI.Avatar.avatar
          name={@user.name || @user.user_name || "U"}
          src={@user.image_path}
          size={:lg}
          rounded={:xl}
        />
        <div>
          <h3 class="font-bold text-[#f0ece6]">{@user.name}</h3>
          <p class="text-sm text-t66-text-muted">@{@user.user_name}</p>
          <%= if @user.bio do %>
            <p class="text-sm text-t66-text-secondary mt-1 line-clamp-1">{@user.bio}</p>
          <% end %>
        </div>
      </div>
      <div class="flex gap-2 w-full sm:w-auto">
        <.link
          navigate={~p"/people/#{@user.user_name}"}
          class="flex-1 sm:flex-initial inline-flex items-center justify-center gap-2 bg-white/[0.04] text-[#8a8680] px-5 py-2.5 rounded-xl font-bold text-sm border border-white/[0.06] hover:border-white/[0.12] hover:text-[#f0ece6] transition-colors"
        >
          <.icon name="hero-user" class="w-4 h-4" /> View Profile
        </.link>
        <%= case @tab do %>
          <% "following" -> %>
            <button
              phx-click="unfollow_user"
              phx-value-user_id={@user.id}
              data-confirm="Are you sure you want to unfollow this user?"
              class="flex-1 sm:flex-initial inline-flex items-center justify-center gap-2 bg-transparent text-[#ef4444] px-5 py-2.5 rounded-xl font-bold text-sm border border-[rgba(239,68,68,0.3)] hover:bg-[rgba(239,68,68,0.12)] transition-colors"
            >
              <.icon name="hero-user-minus" class="w-4 h-4" /> Unfollow
            </button>
          <% "followers" -> %>
            <button
              phx-click="remove_follower"
              phx-value-user_id={@user.id}
              data-confirm="Are you sure you want to remove this follower?"
              class="flex-1 sm:flex-initial inline-flex items-center justify-center gap-2 bg-transparent text-[#ef4444] px-5 py-2.5 rounded-xl font-bold text-sm border border-[rgba(239,68,68,0.3)] hover:bg-[rgba(239,68,68,0.12)] transition-colors"
            >
              <.icon name="hero-x-mark" class="w-4 h-4" /> Remove
            </button>
          <% "friends" -> %>
            <button
              phx-click="remove_friend"
              phx-value-user_id={@user.id}
              data-confirm="Are you sure you want to remove this friend?"
              class="flex-1 sm:flex-initial inline-flex items-center justify-center gap-2 bg-transparent text-[#ef4444] px-5 py-2.5 rounded-xl font-bold text-sm border border-[rgba(239,68,68,0.3)] hover:bg-[rgba(239,68,68,0.12)] transition-colors"
            >
              <.icon name="hero-user-minus" class="w-4 h-4" /> Remove Friend
            </button>
          <% _ -> %>
        <% end %>
      </div>
    </div>
    """
  end
end
