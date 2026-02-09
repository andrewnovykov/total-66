defmodule HeadsUpWeb.UsersLive.Show do
  use HeadsUpWeb, :live_view
  alias HeadsUp.{Accounts, Challenges, Messaging, Reports}
  import HeadsUpWeb.Helpers.AvatarHelper

  def mount(%{"username" => username}, _session, socket) do
    # Try to find user by username first
    user = Accounts.get_user_by_username(username)

    # If not found by username, check if it's an ID or "user-{id}" format
    user =
      if is_nil(user) do
        cond do
          String.starts_with?(username, "user-") ->
            case Integer.parse(String.replace_prefix(username, "user-", "")) do
              {id, ""} -> Accounts.get_user(id)
              _ -> nil
            end

          true ->
            case Integer.parse(username) do
              {id, ""} -> Accounts.get_user(id)
              _ -> nil
            end
        end
      else
        user
      end

    if user do
      followers_count_task = Task.async(fn -> Accounts.get_followers_count(user.id) end)
      following_count_task = Task.async(fn -> Accounts.get_following_count(user.id) end)
      friends_count_task = Task.async(fn -> Accounts.get_friends_count(user.id) end)

      user_challenges_task =
        Task.async(fn -> Challenges.list_participating_challenges(user.id) end)

      followers_count = Task.await(followers_count_task)
      following_count = Task.await(following_count_task)
      friends_count = Task.await(friends_count_task)
      user_challenges = Task.await(user_challenges_task)

      {is_following, friendship_status, can_follow} =
        if socket.assigns[:current_user] do
          current_user_id = socket.assigns.current_user.id
          is_following = Accounts.is_following?(current_user_id, user.id)
          are_friends = Accounts.are_friends?(current_user_id, user.id)

          friendship_status =
            cond do
              are_friends ->
                :friends

              req = Accounts.get_friend_request(current_user_id, user.id) ->
                if req.status == "pending", do: :request_sent, else: :none

              req = Accounts.get_friend_request(user.id, current_user_id) ->
                if req.status == "pending", do: :request_received, else: :none

              true ->
                :none
            end

          can_follow =
            case user.privacy do
              "public" -> true
              "private" -> false
              "friends_only" -> are_friends
              nil -> true
              _ -> true
            end

          {is_following, friendship_status, can_follow}
        else
          {false, :none, user.privacy == "public" or user.privacy == nil}
        end

      can_view_private_content =
        if socket.assigns[:current_user] do
          current_user_id = socket.assigns.current_user.id
          is_owner = current_user_id == user.id
          is_public = user.privacy == "public" or user.privacy == nil

          is_friends_only_and_friend =
            user.privacy == "friends_only" and Accounts.are_friends?(current_user_id, user.id)

          is_owner or is_public or is_friends_only_and_friend
        else
          user.privacy == "public" or user.privacy == nil
        end

      user_level = HeadsUp.ActivityService.get_current_user_level(user.id)

      is_own_profile =
        socket.assigns[:current_user] != nil and
          socket.assigns.current_user.id == user.id

      socket =
        socket
        |> assign(:user, user)
        |> assign(:user_level, user_level)
        |> assign(:is_own_profile, is_own_profile)
        |> assign(:followers_count, followers_count)
        |> assign(:following_count, following_count)
        |> assign(:friends_count, friends_count)
        |> assign(:user_challenges, user_challenges)
        |> assign(:is_following, is_following)
        |> assign(:friendship_status, friendship_status)
        |> assign(:can_follow, can_follow)
        |> assign(:can_view_private_content, can_view_private_content)
        |> assign(:editing_about, false)
        |> assign(:editing_bio, false)
        |> assign(:show_report_modal, false)
        |> assign(:report_reason, "")
        |> assign(:report_description, "")
        |> assign(:about_form, to_form(%{"about" => user.about || ""}))
        |> assign(:bio_form, to_form(%{"bio" => user.bio || ""}))

      layout =
        if is_own_profile,
          do: {HeadsUpWeb.Layouts, :app},
          else: {HeadsUpWeb.Layouts, :public}

      {:ok, socket, layout: layout}
    else
      {:ok,
       socket
       |> put_flash(:error, "User '#{username}' not found")
       |> push_navigate(to: ~p"/people")}
    end
  end

  # -- Event Handlers (unchanged logic) --

  def handle_event("toggle_follow", _params, socket) do
    if socket.assigns[:current_user] do
      current_user_id = socket.assigns.current_user.id
      user_id = socket.assigns.user.id

      result =
        if socket.assigns.is_following do
          Accounts.unfollow_user(current_user_id, user_id)
        else
          Accounts.follow_user(current_user_id, user_id)
        end

      case result do
        {:ok, _} ->
          socket =
            socket
            |> assign(:is_following, !socket.assigns.is_following)
            |> assign(:followers_count, Accounts.get_followers_count(user_id))

          {:noreply, socket}

        {:error, :user_is_private} ->
          {:noreply, put_flash(socket, :error, "This user's profile is private")}

        {:error, :must_be_friends} ->
          {:noreply, put_flash(socket, :error, "You must be friends to follow this user")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Unable to follow/unfollow user")}
      end
    else
      {:noreply, put_flash(socket, :error, "You must be logged in to follow users")}
    end
  end

  def handle_event("send_friend_request", _params, socket) do
    if socket.assigns[:current_user] do
      current_user_id = socket.assigns.current_user.id
      user_id = socket.assigns.user.id

      case Accounts.send_friend_request(current_user_id, user_id) do
        {:ok, _} ->
          socket = assign(socket, :friendship_status, :request_sent)
          {:noreply, put_flash(socket, :info, "Friend request sent")}

        {:error, :friendship_already_exists} ->
          {:noreply, put_flash(socket, :error, "Friendship already exists")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Unable to send friend request")}
      end
    else
      {:noreply, put_flash(socket, :error, "You must be logged in to send friend requests")}
    end
  end

  def handle_event("cancel_friend_request", _params, socket) do
    if socket.assigns[:current_user] do
      current_user_id = socket.assigns.current_user.id
      user_id = socket.assigns.user.id

      case Accounts.cancel_friend_request(current_user_id, user_id) do
        {:ok, _} ->
          socket = assign(socket, :friendship_status, :none)
          {:noreply, put_flash(socket, :info, "Friend request cancelled")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Unable to cancel friend request")}
      end
    else
      {:noreply, put_flash(socket, :error, "You must be logged in")}
    end
  end

  def handle_event("accept_friend_request", _params, socket) do
    if socket.assigns[:current_user] do
      current_user_id = socket.assigns.current_user.id
      user_id = socket.assigns.user.id

      case Accounts.accept_friend_request(current_user_id, user_id) do
        {:ok, _} ->
          socket = assign(socket, :friendship_status, :friends)
          {:noreply, put_flash(socket, :info, "Friend request accepted")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Unable to accept friend request")}
      end
    else
      {:noreply, put_flash(socket, :error, "You must be logged in")}
    end
  end

  def handle_event("decline_friend_request", _params, socket) do
    if socket.assigns[:current_user] do
      current_user_id = socket.assigns.current_user.id
      user_id = socket.assigns.user.id

      case Accounts.decline_friend_request(current_user_id, user_id) do
        {:ok, _} ->
          socket = assign(socket, :friendship_status, :none)
          {:noreply, put_flash(socket, :info, "Friend request declined")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Unable to decline friend request")}
      end
    else
      {:noreply, put_flash(socket, :error, "You must be logged in")}
    end
  end

  def handle_event("remove_friend", _params, socket) do
    if socket.assigns[:current_user] do
      current_user_id = socket.assigns.current_user.id
      user_id = socket.assigns.user.id

      case Accounts.remove_friend(current_user_id, user_id) do
        {:ok, _} ->
          socket = assign(socket, :friendship_status, :none)
          {:noreply, put_flash(socket, :info, "Friend removed")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Unable to remove friend")}
      end
    else
      {:noreply, put_flash(socket, :error, "You must be logged in")}
    end
  end

  def handle_event("start_message", _params, socket) do
    if socket.assigns[:current_user] do
      current_user_id = socket.assigns.current_user.id
      user_id = socket.assigns.user.id

      if Accounts.are_friends?(current_user_id, user_id) do
        case Messaging.get_or_create_conversation(current_user_id, user_id) do
          {:ok, conversation} ->
            {:noreply, push_navigate(socket, to: ~p"/messages/#{conversation.id}")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Unable to start conversation")}
        end
      else
        {:noreply, put_flash(socket, :error, "You must be friends to send messages")}
      end
    else
      {:noreply, put_flash(socket, :error, "You must be logged in to send messages")}
    end
  end

  def handle_event("edit_about", _params, socket) do
    if socket.assigns[:current_user] && socket.assigns.current_user.id == socket.assigns.user.id do
      {:noreply, assign(socket, :editing_about, true)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("edit_bio", _params, socket) do
    if socket.assigns[:current_user] && socket.assigns.current_user.id == socket.assigns.user.id do
      {:noreply, assign(socket, :editing_bio, true)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("cancel_edit_about", _params, socket) do
    {:noreply, assign(socket, :editing_about, false)}
  end

  def handle_event("cancel_edit_bio", _params, socket) do
    {:noreply, assign(socket, :editing_bio, false)}
  end

  def handle_event("save_about", %{"about" => about}, socket) do
    if socket.assigns[:current_user] && socket.assigns.current_user.id == socket.assigns.user.id do
      case Accounts.update_user(socket.assigns.user, %{about: about}) do
        {:ok, updated_user} ->
          socket =
            socket
            |> assign(:user, updated_user)
            |> assign(:editing_about, false)
            |> put_flash(:info, "About section updated successfully")

          {:noreply, socket}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to update about section")}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("save_bio", %{"bio" => bio}, socket) do
    if socket.assigns[:current_user] && socket.assigns.current_user.id == socket.assigns.user.id do
      case Accounts.update_user(socket.assigns.user, %{bio: bio}) do
        {:ok, updated_user} ->
          socket =
            socket
            |> assign(:user, updated_user)
            |> assign(:editing_bio, false)
            |> put_flash(:info, "Bio updated successfully")

          {:noreply, socket}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to update bio")}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("view_user", %{"user-id" => user_id}, socket) do
    user = Accounts.get_user(user_id)

    if user do
      {:noreply, push_navigate(socket, to: ~p"/people/#{user.user_name}")}
    else
      {:noreply, socket}
    end
  end

  def handle_event("cycle_privacy", _params, socket) do
    user = socket.assigns.user
    next_privacy = next_privacy(user.privacy)

    case Accounts.update_user(user, %{privacy: next_privacy}) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> assign(:user, updated_user)
         |> put_flash(:info, "Profile set to #{privacy_label(next_privacy)}")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not update privacy")}
    end
  end

  defp next_privacy("public"), do: "friends_only"
  defp next_privacy("friends_only"), do: "private"
  defp next_privacy("private"), do: "public"
  defp next_privacy(_), do: "public"

  defp privacy_icon("public"), do: "hero-globe-alt"
  defp privacy_icon("friends_only"), do: "hero-user-group"
  defp privacy_icon("private"), do: "hero-lock-closed"
  defp privacy_icon(_), do: "hero-globe-alt"

  defp privacy_label("public"), do: "Public"
  defp privacy_label("friends_only"), do: "Friends Only"
  defp privacy_label("private"), do: "Private"
  defp privacy_label(_), do: "Public"

  # -- Report Event Handlers --

  def handle_event("show_report_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_report_modal, true)
     |> assign(:report_reason, "")
     |> assign(:report_description, "")}
  end

  def handle_event("hide_report_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_report_modal, false)
     |> assign(:report_reason, "")
     |> assign(:report_description, "")}
  end

  def handle_event("update_report_reason", %{"report_reason" => reason}, socket) do
    {:noreply, assign(socket, :report_reason, reason)}
  end

  def handle_event("update_report_description", %{"report_description" => desc}, socket) do
    {:noreply, assign(socket, :report_description, desc)}
  end

  def handle_event("submit_report", _params, socket) do
    reason = socket.assigns.report_reason
    description = socket.assigns.report_description
    reporter_id = socket.assigns.current_user.id
    reported_user_id = socket.assigns.user.id

    if reason == "" do
      {:noreply, put_flash(socket, :error, "Please select a reason for your report")}
    else
      attrs = %{reason: reason, description: description}

      case Reports.report_user(reported_user_id, reporter_id, attrs) do
        {:ok, _report} ->
          {:noreply,
           socket
           |> assign(:show_report_modal, false)
           |> assign(:report_reason, "")
           |> assign(:report_description, "")
           |> put_flash(:info, "Report submitted. Thank you for helping keep the community safe.")}

        {:error, :already_reported} ->
          {:noreply,
           socket
           |> assign(:show_report_modal, false)
           |> put_flash(:info, "You have already reported this user.")}

        {:error, :cannot_report_own} ->
          {:noreply,
           socket
           |> assign(:show_report_modal, false)
           |> put_flash(:error, "You cannot report yourself.")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to submit report. Please try again.")}
      end
    end
  end

  # -- Render --

  def render(assigns) do
    stats = challenge_stats(assigns.user_challenges)
    has_completed = stats.completed > 0

    assigns =
      assigns
      |> assign(:stats, stats)
      |> assign(:has_completed, has_completed)

    ~H"""
    <style>
      @keyframes bannerShift {
        from { transform: translate(0, 0); }
        to { transform: translate(-5%, 3%); }
      }
    </style>

    <%!-- Banner --%>
    <div class={[
      "h-[220px] sm:h-[220px] h-[160px] relative overflow-hidden",
      if(@is_own_profile, do: "-mx-5 sm:-mx-10 -mt-10 rounded-b-2xl", else: "")
    ]} style="background: linear-gradient(135deg, #1a0a00 0%, #0a0a0a 40%, #0a1510 100%);">
      <div class="absolute -top-1/2 -left-1/2 w-[200%] h-[200%]" style="background: radial-gradient(circle at 30% 80%, rgba(255, 77, 0, 0.08) 0%, transparent 50%), radial-gradient(circle at 70% 20%, rgba(0, 212, 170, 0.05) 0%, transparent 50%); animation: bannerShift 15s ease infinite alternate;"></div>
      <div class="absolute bottom-0 left-0 right-0 h-20" style="background: linear-gradient(to top, #0a0a0a, transparent);"></div>
    </div>

    <%!-- Profile Container --%>
    <div class={[
      "-mt-20 pb-24 relative z-[2]",
      if(@is_own_profile, do: "", else: "max-w-[1000px] mx-auto px-5 sm:px-10")
    ]}>

      <%= if !@can_view_private_content do %>
        <%!-- ══════ PRIVATE PROFILE VIEW ══════ --%>
        <div class="flex flex-col sm:flex-row items-center sm:items-end gap-5 sm:gap-8 mb-10 text-center sm:text-left">
          <%!-- Lock avatar placeholder --%>
          <div class="relative flex-shrink-0">
            <div class="w-[130px] h-[130px] rounded-full border-4 flex items-center justify-center" style="border-color: #0a0a0a; box-shadow: 0 0 0 2px rgba(255,77,0,0.3), 0 8px 32px rgba(0,0,0,0.5); background: #131313;">
              <.icon name="hero-lock-closed-solid" class="w-14 h-14 text-[#5a5754]" />
            </div>
          </div>
          <div class="flex-1 pb-1.5">
            <h1 class="text-3xl sm:text-4xl font-bold tracking-wide leading-tight mb-0.5" style="font-family: 'Bebas Neue', sans-serif; color: #f0ece6; letter-spacing: 3px;">
              {@user.name || "Anonymous"}
            </h1>
            <p class="text-base mb-2.5" style="color: #5a5754;">@{@user.user_name}</p>
            <span class="inline-flex items-center gap-1.5 px-3.5 py-1 rounded-full text-xs font-bold uppercase tracking-widest" style="color: #f0ece6; background: rgba(255,255,255,0.06);">
              <.icon name="hero-lock-closed" class="w-3.5 h-3.5" /> Private Person
            </span>
          </div>
        </div>

        <%!-- Action Buttons for private profiles --%>
        <%= if @current_user && @current_user.id != @user.id do %>
          <div class="flex flex-wrap gap-2.5 mb-12 justify-center sm:justify-start">
            <%= case @friendship_status do %>
              <% :none -> %>
                <button
                  phx-click="send_friend_request"
                  class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm uppercase tracking-wider border-none cursor-pointer transition-all duration-300 hover:-translate-y-0.5"
                  style="background: #131313; color: #f0ece6; border: 1px solid rgba(255,255,255,0.06);"
                >
                  <.icon name="hero-heart" class="w-4 h-4" />
                  <span>Add Friend</span>
                </button>
              <% :request_sent -> %>
                <button
                  phx-click="cancel_friend_request"
                  data-confirm="Are you sure you want to cancel this friend request?"
                  class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm uppercase tracking-wider border-none cursor-pointer transition-all duration-300 hover:-translate-y-0.5"
                  style="background: #131313; color: #ff4d00; border: 1px solid rgba(255,77,0,0.3);"
                >
                  <.icon name="hero-clock" class="w-4 h-4" />
                  <span>Cancel Request</span>
                </button>
              <% :request_received -> %>
                <button
                  phx-click="accept_friend_request"
                  class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm uppercase tracking-wider border-none cursor-pointer transition-all duration-300 hover:-translate-y-0.5"
                  style="background: #22c55e; color: #fff; box-shadow: 0 0 30px rgba(34,197,94,0.2);"
                >
                  <.icon name="hero-check" class="w-4 h-4" />
                  <span>Accept</span>
                </button>
                <button
                  phx-click="decline_friend_request"
                  class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm uppercase tracking-wider border-none cursor-pointer transition-all duration-300 hover:-translate-y-0.5"
                  style="background: #131313; color: #ef4444; border: 1px solid rgba(239,68,68,0.3);"
                >
                  <.icon name="hero-x-mark" class="w-4 h-4" />
                  <span>Decline</span>
                </button>
              <% :friends -> %>
                <button
                  phx-click="start_message"
                  class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm uppercase tracking-wider border-none cursor-pointer transition-all duration-300 hover:-translate-y-0.5"
                  style="background: #131313; color: #f0ece6; border: 1px solid rgba(255,255,255,0.06);"
                >
                  <.icon name="hero-chat-bubble-left-right" class="w-4 h-4" />
                  <span>Message</span>
                </button>
                <button
                  phx-click="remove_friend"
                  data-confirm="Are you sure you want to remove this friend?"
                  class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm uppercase tracking-wider border-none cursor-pointer transition-all duration-300 hover:-translate-y-0.5"
                  style="background: #131313; color: #ef4444; border: 1px solid rgba(239,68,68,0.3);"
                >
                  <.icon name="hero-user-minus" class="w-4 h-4" />
                  <span>Remove Friend</span>
                </button>
            <% end %>
          </div>
        <% end %>

        <%!-- Private content placeholder --%>
        <div class="rounded-2xl p-10 text-center" style="background: #131313; border: 1px solid rgba(255,255,255,0.06);">
          <.icon name="hero-lock-closed" class="w-10 h-10 mx-auto mb-3 text-[#5a5754]" />
          <p class="text-sm" style="color: #8a8680;">
            <%= if @user.privacy == "private" do %>
              This user's profile is private. Send a friend request to see their content.
            <% else %>
              This user shares their profile with friends only. Send a friend request to connect.
            <% end %>
          </p>
        </div>

      <% else %>
        <%!-- ══════ PUBLIC PROFILE VIEW ══════ --%>

        <%!-- Profile Header: Avatar + Name + Meta --%>
        <div class="flex flex-col sm:flex-row items-center sm:items-end gap-5 sm:gap-8 mb-10 text-center sm:text-left">
          <div class="relative flex-shrink-0">
            <div class="w-[130px] h-[130px] rounded-full overflow-hidden border-4" style="border-color: #0a0a0a; box-shadow: 0 0 0 2px rgba(255,77,0,0.3), 0 8px 32px rgba(0,0,0,0.5);">
              <HeadsUpWeb.Components.UI.Avatar.avatar
                name={@user.name || @user.user_name || "U"}
                src={get_user_avatar(@user)}
                size={:xxl}
                rounded={:full}
                class="w-full h-full"
              />
            </div>
            <%= if @has_completed do %>
              <div class="absolute bottom-1 right-1 w-[38px] h-[38px] rounded-full flex items-center justify-center text-lg border-[3px]" style="background: #ffc642; box-shadow: 0 2px 12px rgba(255,198,66,0.5); border-color: #0a0a0a;">
                <span>&#127942;</span>
              </div>
            <% end %>
          </div>
          <div class="flex-1 pb-1.5">
            <h1 class="text-3xl sm:text-4xl font-bold tracking-wide leading-tight mb-0.5" style="font-family: 'Bebas Neue', sans-serif; color: #f0ece6; letter-spacing: 3px;">
              {@user.name || "Anonymous"}
            </h1>
            <p class="text-base mb-2.5" style="color: #5a5754;">@{@user.user_name}</p>
            <div class="flex flex-wrap gap-5 items-center justify-center sm:justify-start">
              <span class="flex items-center gap-1.5 text-sm" style="color: #8a8680;">
                <.icon name="hero-calendar" class="w-4 h-4" />
                Joined {format_joined_date(@user.inserted_at)}
              </span>
              <span class="flex items-center gap-1.5 text-sm" style="color: #8a8680;">
                <span class="font-bold" style="color: #f0ece6;">{@followers_count}</span> followers
              </span>
              <span class="flex items-center gap-1.5 text-sm" style="color: #8a8680;">
                <span class="font-bold" style="color: #f0ece6;">{@following_count}</span> following
              </span>
              <span class="flex items-center gap-1.5 text-sm" style="color: #8a8680;">
                <span class="font-bold" style="color: #f0ece6;">{@friends_count}</span> friends
              </span>
              <%= if @has_completed do %>
                <span class="inline-flex items-center gap-1.5 px-3.5 py-1 rounded-full text-xs font-bold uppercase tracking-widest" style="color: #ffc642; background: rgba(255,198,66,0.15);">
                  <span>&#127942;</span> Finisher
                </span>
              <% end %>
            </div>
            <%!-- Privacy Toggle (owner only) --%>
            <%= if @current_user && @current_user.id == @user.id do %>
              <div class="mt-3">
                <button
                  phx-click="cycle_privacy"
                  class="inline-flex items-center gap-2 px-4 py-2 rounded-xl font-bold text-xs uppercase tracking-wider cursor-pointer transition-all duration-300 hover:-translate-y-0.5"
                  style="background: #131313; color: #8a8680; border: 1px solid rgba(255,255,255,0.06);"
                >
                  <.icon name={privacy_icon(@user.privacy)} class="w-4 h-4" />
                  <span>{privacy_label(@user.privacy)}</span>
                  <.icon name="hero-chevron-right" class="w-3.5 h-3.5 text-[#5a5754]" />
                </button>
              </div>
            <% end %>
          </div>
        </div>

        <%!-- Action Buttons --%>
        <%= if @current_user && @current_user.id != @user.id do %>
          <div class="flex flex-wrap gap-2.5 mb-12 justify-center sm:justify-start">
            <%= if @can_follow do %>
              <button
                phx-click="toggle_follow"
                class={[
                  "inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm uppercase tracking-wider border-none cursor-pointer transition-all duration-300 hover:-translate-y-0.5",
                  if(@is_following, do: "", else: "")
                ]}
                style={if @is_following, do: "background: transparent; color: #ff4d00; border: 1px solid rgba(255,77,0,0.3);", else: "background: #ff4d00; color: #fff; box-shadow: 0 0 30px rgba(255,77,0,0.2);"}
              >
                <.icon name={if @is_following, do: "hero-user-minus", else: "hero-user-plus"} class="w-4 h-4" />
                <span>{if @is_following, do: "Unfollow", else: "Follow"}</span>
              </button>
            <% end %>

            <%!-- Disabled message button for non-friends --%>
            <%= if @friendship_status != :friends do %>
              <button
                disabled
                class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm uppercase tracking-wider cursor-not-allowed opacity-40"
                style="background: #131313; color: #5a5754; border: 1px solid rgba(255,255,255,0.04);"
                title="You must be friends to message"
              >
                <.icon name="hero-chat-bubble-left-right" class="w-4 h-4" />
                <span>Message</span>
              </button>
            <% end %>

            <%= case @friendship_status do %>
              <% :none -> %>
                <button
                  phx-click="send_friend_request"
                  class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm uppercase tracking-wider border-none cursor-pointer transition-all duration-300 hover:-translate-y-0.5"
                  style="background: #131313; color: #f0ece6; border: 1px solid rgba(255,255,255,0.06);"
                >
                  <.icon name="hero-heart" class="w-4 h-4" />
                  <span>Add Friend</span>
                </button>
              <% :request_sent -> %>
                <button
                  phx-click="cancel_friend_request"
                  data-confirm="Are you sure you want to cancel this friend request?"
                  class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm uppercase tracking-wider border-none cursor-pointer transition-all duration-300 hover:-translate-y-0.5"
                  style="background: #131313; color: #ff4d00; border: 1px solid rgba(255,77,0,0.3);"
                >
                  <.icon name="hero-clock" class="w-4 h-4" />
                  <span>Cancel Request</span>
                </button>
              <% :request_received -> %>
                <button
                  phx-click="accept_friend_request"
                  class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm uppercase tracking-wider border-none cursor-pointer transition-all duration-300 hover:-translate-y-0.5"
                  style="background: #22c55e; color: #fff; box-shadow: 0 0 30px rgba(34,197,94,0.2);"
                >
                  <.icon name="hero-check" class="w-4 h-4" />
                  <span>Accept</span>
                </button>
                <button
                  phx-click="decline_friend_request"
                  class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm uppercase tracking-wider border-none cursor-pointer transition-all duration-300 hover:-translate-y-0.5"
                  style="background: #131313; color: #ef4444; border: 1px solid rgba(239,68,68,0.3);"
                >
                  <.icon name="hero-x-mark" class="w-4 h-4" />
                  <span>Decline</span>
                </button>
              <% :friends -> %>
                <button
                  phx-click="start_message"
                  class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm uppercase tracking-wider border-none cursor-pointer transition-all duration-300 hover:-translate-y-0.5"
                  style="background: #131313; color: #f0ece6; border: 1px solid rgba(255,255,255,0.06);"
                >
                  <.icon name="hero-chat-bubble-left-right" class="w-4 h-4" />
                  <span>Message</span>
                </button>
                <button
                  phx-click="remove_friend"
                  data-confirm="Are you sure you want to remove this friend?"
                  class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm uppercase tracking-wider border-none cursor-pointer transition-all duration-300 hover:-translate-y-0.5"
                  style="background: #131313; color: #ef4444; border: 1px solid rgba(239,68,68,0.3);"
                >
                  <.icon name="hero-user-minus" class="w-4 h-4" />
                  <span>Remove Friend</span>
                </button>
            <% end %>

            <%!-- Report User --%>
            <button
              phx-click="show_report_modal"
              class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm uppercase tracking-wider border-none cursor-pointer transition-all duration-300 hover:-translate-y-0.5"
              style="background: #131313; color: #8a8680; border: 1px solid rgba(255,255,255,0.06);"
              title="Report user"
            >
              <.icon name="hero-flag" class="w-4 h-4" />
              <span>Report</span>
            </button>
          </div>
        <% end %>

        <%!-- Stats Row --%>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-12">
          <div class="rounded-2xl p-6 text-center transition-all duration-300 hover:-translate-y-0.5" style="background: #131313; border: 1px solid rgba(255,255,255,0.06);">
            <div class="text-4xl font-bold leading-none" style="font-family: 'Bebas Neue', sans-serif; color: #ff4d00;">{@stats.attempts}</div>
            <div class="text-xs uppercase tracking-widest mt-1" style="color: #5a5754;">Attempts</div>
          </div>
          <div class="rounded-2xl p-6 text-center transition-all duration-300 hover:-translate-y-0.5" style="background: #131313; border: 1px solid rgba(255,255,255,0.06);">
            <div class="text-4xl font-bold leading-none" style="font-family: 'Bebas Neue', sans-serif; color: #22c55e;">{@stats.completed}</div>
            <div class="text-xs uppercase tracking-widest mt-1" style="color: #5a5754;">Completed</div>
          </div>
          <div class="rounded-2xl p-6 text-center transition-all duration-300 hover:-translate-y-0.5" style="background: #131313; border: 1px solid rgba(255,255,255,0.06);">
            <div class="text-4xl font-bold leading-none" style="font-family: 'Bebas Neue', sans-serif; color: #ef4444;">{@stats.failed}</div>
            <div class="text-xs uppercase tracking-widest mt-1" style="color: #5a5754;">Didn't Finish</div>
          </div>
          <div class="rounded-2xl p-6 text-center transition-all duration-300 hover:-translate-y-0.5" style="background: #131313; border: 1px solid rgba(255,255,255,0.06);">
            <div class="text-4xl font-bold leading-none" style="font-family: 'Bebas Neue', sans-serif; color: #ffc642;">{@stats.success_rate}%</div>
            <div class="text-xs uppercase tracking-widest mt-1" style="color: #5a5754;">Success Rate</div>
          </div>
        </div>

        <%!-- Section Divider --%>
        <div class="h-px mb-12" style="background: rgba(255,255,255,0.06);"></div>

        <%!-- About Section --%>
        <div class="mb-14">
          <div class="flex items-center justify-between mb-1.5">
            <h2 class="text-3xl font-bold tracking-wide" style="font-family: 'Bebas Neue', sans-serif; color: #f0ece6; letter-spacing: 2px;">About</h2>
            <%= if @current_user && @current_user.id == @user.id && !@editing_about do %>
              <button
                phx-click="edit_about"
                class="text-sm font-bold cursor-pointer transition-colors duration-300"
                style="color: #ff4d00;"
              >
                Edit
              </button>
            <% end %>
          </div>
          <p class="text-sm mb-7" style="color: #5a5754;">Personal details</p>

          <%= if @editing_about do %>
            <.form for={@about_form} phx-submit="save_about" class="space-y-4">
              <textarea
                name="about"
                rows="4"
                class="w-full px-5 py-4 rounded-xl text-sm resize-none focus:outline-none focus:ring-2"
                style="background: #131313; border: 1px solid rgba(255,255,255,0.06); color: #f0ece6; focus:ring-color: rgba(255,77,0,0.3);"
                placeholder="Tell us about yourself..."
              ><%= @user.about %></textarea>
              <div class="flex gap-3">
                <button
                  type="submit"
                  class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm uppercase tracking-wider cursor-pointer transition-all duration-300 hover:-translate-y-0.5"
                  style="background: #ff4d00; color: #fff;"
                >
                  Save
                </button>
                <button
                  type="button"
                  phx-click="cancel_edit_about"
                  class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm uppercase tracking-wider cursor-pointer transition-all duration-300"
                  style="background: #131313; color: #8a8680; border: 1px solid rgba(255,255,255,0.06);"
                >
                  Cancel
                </button>
              </div>
            </.form>
          <% else %>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div class="flex items-center gap-3.5 rounded-xl p-5" style="background: #131313; border: 1px solid rgba(255,255,255,0.06);">
                <div class="w-10 h-10 rounded-[10px] flex items-center justify-center flex-shrink-0" style="background: rgba(255,255,255,0.04);">
                  <.icon name="hero-user" class="w-5 h-5 text-[#8a8680]" />
                </div>
                <div>
                  <div class="text-xs uppercase tracking-widest" style="color: #5a5754;">Bio</div>
                  <div class="text-sm font-bold" style="color: #f0ece6;">
                    <%= if @editing_bio do %>
                      <.form for={@bio_form} phx-submit="save_bio" class="flex gap-2 items-center mt-1">
                        <input
                          type="text"
                          name="bio"
                          value={@user.bio}
                          class="px-3 py-1.5 rounded-lg text-sm focus:outline-none focus:ring-2"
                          style="background: #1c1c1c; border: 1px solid rgba(255,255,255,0.1); color: #f0ece6;"
                          placeholder="Short bio..."
                          maxlength="100"
                        />
                        <button type="submit" class="text-xs font-bold px-3 py-1.5 rounded-lg" style="background: #ff4d00; color: #fff;">Save</button>
                        <button type="button" phx-click="cancel_edit_bio" class="text-xs font-bold px-3 py-1.5 rounded-lg" style="background: rgba(255,255,255,0.06); color: #8a8680;">Cancel</button>
                      </.form>
                    <% else %>
                      <div class="group relative inline-block">
                        <span>{@user.bio || "No bio yet"}</span>
                        <%= if @current_user && @current_user.id == @user.id do %>
                          <button phx-click="edit_bio" class="ml-2 opacity-0 group-hover:opacity-100 transition-opacity">
                            <.icon name="hero-pencil-square" class="w-3.5 h-3.5 text-[#5a5754]" />
                          </button>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
              <div class="flex items-center gap-3.5 rounded-xl p-5" style="background: #131313; border: 1px solid rgba(255,255,255,0.06);">
                <div class="w-10 h-10 rounded-[10px] flex items-center justify-center flex-shrink-0" style="background: rgba(255,255,255,0.04);">
                  <.icon name="hero-calendar" class="w-5 h-5 text-[#8a8680]" />
                </div>
                <div>
                  <div class="text-xs uppercase tracking-widest" style="color: #5a5754;">Member Since</div>
                  <div class="text-sm font-bold" style="color: #f0ece6;">{format_joined_date(@user.inserted_at)}</div>
                </div>
              </div>
              <div class="flex items-center gap-3.5 rounded-xl p-5" style="background: #131313; border: 1px solid rgba(255,255,255,0.06);">
                <div class="w-10 h-10 rounded-[10px] flex items-center justify-center flex-shrink-0" style="background: rgba(255,255,255,0.04);">
                  <.icon name="hero-star" class="w-5 h-5 text-[#8a8680]" />
                </div>
                <div>
                  <div class="text-xs uppercase tracking-widest" style="color: #5a5754;">Level</div>
                  <div class="text-sm font-bold" style="color: #f0ece6;">Level {@user_level}</div>
                </div>
              </div>
              <div class="flex items-center gap-3.5 rounded-xl p-5" style="background: #131313; border: 1px solid rgba(255,255,255,0.06);">
                <div class="w-10 h-10 rounded-[10px] flex items-center justify-center flex-shrink-0" style="background: rgba(255,255,255,0.04);">
                  <.icon name="hero-trophy" class="w-5 h-5 text-[#8a8680]" />
                </div>
                <div>
                  <div class="text-xs uppercase tracking-widest" style="color: #5a5754;">Status</div>
                  <div class="text-sm font-bold" style="color: #f0ece6;">{if @has_completed, do: "Finisher", else: "Challenger"}</div>
                </div>
              </div>
              <%= if @user.about do %>
                <div class="sm:col-span-2 flex items-start gap-3.5 rounded-xl p-5" style="background: #131313; border: 1px solid rgba(255,255,255,0.06);">
                  <div class="w-10 h-10 rounded-[10px] flex items-center justify-center flex-shrink-0" style="background: rgba(255,255,255,0.04);">
                    <.icon name="hero-chat-bubble-bottom-center-text" class="w-5 h-5 text-[#8a8680]" />
                  </div>
                  <div>
                    <div class="text-xs uppercase tracking-widest" style="color: #5a5754;">About</div>
                    <div class="text-sm font-bold whitespace-pre-wrap" style="color: #f0ece6;">{@user.about}</div>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>

        <%!-- Section Divider --%>
        <div class="h-px mb-12" style="background: rgba(255,255,255,0.06);"></div>

        <%!-- Challenge History --%>
        <div class="mb-14">
          <h2 class="text-3xl font-bold tracking-wide mb-1.5" style="font-family: 'Bebas Neue', sans-serif; color: #f0ece6; letter-spacing: 2px;">Challenge History</h2>
          <p class="text-sm mb-7" style="color: #5a5754;">All attempts, victories, and lessons learned</p>

          <%= if Enum.empty?(@user_challenges) do %>
            <div class="rounded-2xl p-10 text-center" style="background: #131313; border: 1px solid rgba(255,255,255,0.06);">
              <.icon name="hero-bolt" class="w-10 h-10 mx-auto mb-3 text-[#5a5754]" />
              <p class="text-sm font-bold" style="color: #5a5754;">No challenges yet.</p>
            </div>
          <% else %>
            <div class="flex flex-col gap-3.5">
              <.link
                :for={challenge <- @user_challenges}
                navigate={~p"/challenges/#{challenge.id}"}
                class="block group"
              >
                <div class={[
                  "flex flex-col sm:flex-row items-center gap-5 p-5 sm:p-6 rounded-2xl relative overflow-hidden transition-all duration-300 hover:border-white/10",
                  challenge_card_class(challenge.status)
                ]} style="background: #131313; border: 1px solid rgba(255,255,255,0.06);">
                  <%!-- Left accent bar --%>
                  <div class={[
                    "absolute left-0 top-0 bottom-0 w-1 rounded-l-2xl",
                    status_accent_color(challenge.status)
                  ]}></div>

                  <%!-- Challenge icon --%>
                  <div class="w-[50px] h-[50px] rounded-[14px] flex items-center justify-center flex-shrink-0" style={"background: #{status_icon_bg(challenge.status)};"}>
                    <span style={"color: #{status_color(challenge.status)};"}><.icon name={challenge_status_icon(challenge.status)} class="w-6 h-6" /></span>
                  </div>

                  <%!-- Challenge info --%>
                  <div class="flex-1 min-w-0 text-center sm:text-left">
                    <div class="flex items-center gap-2.5 justify-center sm:justify-start flex-wrap">
                      <span class="font-bold text-sm" style="color: #f0ece6;">{challenge.title}</span>
                    </div>
                    <div class="text-sm mt-0.5" style="color: #5a5754;">
                      {format_date_range(challenge)}
                    </div>
                  </div>

                  <%!-- Progress ring + status --%>
                  <div class="flex items-center gap-5 flex-shrink-0">
                    <.progress_ring challenge={challenge} />
                    <span class={[
                      "text-xs uppercase tracking-widest font-bold px-3.5 py-1.5 rounded-full whitespace-nowrap",
                      status_badge_class(challenge.status)
                    ]}>
                      {status_label(challenge.status)}
                    </span>
                  </div>
                </div>
              </.link>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>

    <%!-- Report Modal (dark themed) --%>
    <%= if @show_report_modal do %>
      <div class="fixed inset-0 backdrop-blur-sm flex items-center justify-center p-4 z-50" style="background: rgba(0,0,0,0.7);">
        <div class="max-w-md w-full p-8 rounded-2xl shadow-2xl" style="background: #131313; border: 1px solid rgba(255,255,255,0.06);">
          <div class="flex items-center gap-3 mb-6">
            <div class="w-12 h-12 rounded-xl flex items-center justify-center" style="background: rgba(239,68,68,0.12);">
              <.icon name="hero-flag" class="w-6 h-6 text-[#ef4444]" />
            </div>
            <h3 class="text-xl font-bold" style="color: #f0ece6;">Report User</h3>
          </div>

          <p class="text-sm mb-6" style="color: #5a5754;">
            Help us keep the community safe. Select a reason for your report.
          </p>

          <form phx-submit="submit_report">
            <div class="mb-4">
              <label class="block text-sm font-bold mb-3" style="color: #8a8680;">Reason *</label>
              <div class="space-y-2">
                <%= for reason <- HeadsUp.Reports.Report.reasons() do %>
                  <label class="flex items-center gap-3 p-3 rounded-xl cursor-pointer transition-colors" style={"#{if @report_reason == reason, do: "background: rgba(239,68,68,0.12); border: 1px solid rgba(239,68,68,0.3);", else: "background: rgba(255,255,255,0.04); border: 1px solid rgba(255,255,255,0.06);"}"}>
                    <input
                      type="radio"
                      name="report_reason"
                      value={reason}
                      checked={@report_reason == reason}
                      phx-click="update_report_reason"
                      phx-value-report_reason={reason}
                      class="text-red-500 focus:ring-red-500"
                    />
                    <span class="text-sm font-medium capitalize" style="color: #f0ece6;">{reason}</span>
                  </label>
                <% end %>
              </div>
            </div>

            <div class="mb-6">
              <label for="report_description" class="block text-sm font-bold mb-2" style="color: #8a8680;">
                Additional details (optional)
              </label>
              <textarea
                id="report_description"
                name="report_description"
                rows="3"
                value={@report_description}
                phx-change="update_report_description"
                placeholder="Provide any additional context..."
                maxlength="500"
                class="w-full rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-red-500/30 resize-none focus:outline-none"
                style="background: rgba(255,255,255,0.04); border: 1px solid rgba(255,255,255,0.06); color: #f0ece6;"
              ><%= @report_description %></textarea>
              <div class="text-xs mt-1 text-right" style="color: #5a5754;">
                {String.length(@report_description)}/500
              </div>
            </div>

            <div class="flex justify-end gap-3">
              <button
                type="button"
                phx-click="hide_report_modal"
                class="px-5 py-3 rounded-xl text-sm font-bold cursor-pointer transition-colors"
                style="background: rgba(255,255,255,0.04); color: #8a8680; border: 1px solid rgba(255,255,255,0.06);"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={@report_reason == ""}
                class="px-5 py-3 rounded-xl text-sm font-bold cursor-pointer transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                style="background: #ef4444; color: #fff;"
              >
                Submit Report
              </button>
            </div>
          </form>
        </div>
      </div>
    <% end %>
    """
  end

  # -- Components --

  defp progress_ring(assigns) do
    days_completed = calculate_days_completed(assigns.challenge)
    total_days = assigns.challenge.duration_days || 66
    pct = if total_days > 0, do: round(days_completed / total_days * 100), else: 0
    pct = min(pct, 100)
    circumference = 2 * :math.pi() * 22
    offset = circumference - pct / 100 * circumference

    assigns =
      assigns
      |> assign(:pct, pct)
      |> assign(:circumference, circumference)
      |> assign(:offset, offset)
      |> assign(:ring_color, status_color(assigns.challenge.status))

    ~H"""
    <div class="relative w-[52px] h-[52px]">
      <svg width="52" height="52" style="transform: rotate(-90deg);">
        <circle cx="26" cy="26" r="22" fill="none" stroke="rgba(255,255,255,0.05)" stroke-width="4" />
        <circle
          cx="26" cy="26" r="22"
          fill="none"
          stroke={@ring_color}
          stroke-width="4"
          stroke-linecap="round"
          stroke-dasharray={@circumference}
          stroke-dashoffset={@offset}
          style="transition: stroke-dashoffset 1s ease;"
        />
      </svg>
      <div class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-sm font-bold leading-none" style={"font-family: 'Bebas Neue', sans-serif; color: #{@ring_color};"}>
        {@pct}%
      </div>
    </div>
    """
  end

  # -- Helpers --

  defp challenge_stats(challenges) do
    attempts = length(challenges)
    completed = Enum.count(challenges, &(&1.status == :completed))
    failed = Enum.count(challenges, &(&1.status in [:failed, :cancelled]))
    success_rate = if attempts > 0, do: round(completed / attempts * 100), else: 0

    %{attempts: attempts, completed: completed, failed: failed, success_rate: success_rate}
  end

  defp calculate_days_completed(challenge) do
    cond do
      challenge.status == :completed ->
        challenge.duration_days || 66

      challenge.start_date && challenge.end_date ->
        Date.diff(challenge.end_date, challenge.start_date)

      challenge.start_date ->
        Date.diff(Date.utc_today(), challenge.start_date) |> max(0)

      true ->
        0
    end
  end

  defp format_joined_date(nil), do: "Unknown"

  defp format_joined_date(%NaiveDateTime{} = dt) do
    Calendar.strftime(dt, "%B %Y")
  end

  defp format_joined_date(%DateTime{} = dt) do
    Calendar.strftime(dt, "%B %Y")
  end

  defp format_joined_date(_), do: "Unknown"

  defp format_date_range(challenge) do
    start_str =
      if challenge.start_date do
        Calendar.strftime(challenge.start_date, "%b %d, %Y")
      else
        "N/A"
      end

    end_str =
      if challenge.end_date do
        Calendar.strftime(challenge.end_date, "%b %d, %Y")
      else
        "Present"
      end

    "#{start_str} → #{end_str}"
  end

  defp challenge_card_class(_status), do: ""

  defp status_accent_color(:active), do: "bg-[#ff4d00]"
  defp status_accent_color(:completed), do: "bg-[#22c55e]"
  defp status_accent_color(:failed), do: "bg-[#ef4444]"
  defp status_accent_color(:cancelled), do: "bg-[#ef4444]"
  defp status_accent_color(_), do: "bg-[#ff4d00]"

  defp status_color(:active), do: "#ff4d00"
  defp status_color(:completed), do: "#22c55e"
  defp status_color(:failed), do: "#ef4444"
  defp status_color(:cancelled), do: "#ef4444"
  defp status_color(_), do: "#ff4d00"

  defp status_icon_bg(:active), do: "rgba(255,77,0,0.15)"
  defp status_icon_bg(:completed), do: "rgba(34,197,94,0.12)"
  defp status_icon_bg(:failed), do: "rgba(239,68,68,0.12)"
  defp status_icon_bg(:cancelled), do: "rgba(239,68,68,0.12)"
  defp status_icon_bg(_), do: "rgba(255,77,0,0.15)"

  defp status_badge_class(:active),
    do: "text-[#ff4d00] bg-[rgba(255,77,0,0.15)]"

  defp status_badge_class(:completed),
    do: "text-[#22c55e] bg-[rgba(34,197,94,0.12)]"

  defp status_badge_class(:failed),
    do: "text-[#ef4444] bg-[rgba(239,68,68,0.12)]"

  defp status_badge_class(:cancelled),
    do: "text-[#ef4444] bg-[rgba(239,68,68,0.12)]"

  defp status_badge_class(_),
    do: "text-[#ff4d00] bg-[rgba(255,77,0,0.15)]"

  defp status_label(:active), do: "In Progress"
  defp status_label(:completed), do: "Completed"
  defp status_label(:failed), do: "Didn't Finish"
  defp status_label(:cancelled), do: "Cancelled"
  defp status_label(status), do: status |> to_string() |> String.capitalize()

  defp challenge_status_icon(:active), do: "hero-bolt"
  defp challenge_status_icon(:completed), do: "hero-trophy"
  defp challenge_status_icon(:failed), do: "hero-x-circle"
  defp challenge_status_icon(_), do: "hero-bolt"
end
