defmodule HeadsUpWeb.UsersLive.Show do
  use HeadsUpWeb, :live_view
  alias HeadsUp.{Accounts, Challenges, Goals, Messaging, Reports}
  import HeadsUpWeb.Components.GoalCard
  import HeadsUpWeb.Helpers.AvatarHelper
  import HeadsUpWeb.Components.CommitmentChart

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
      user_goals_task = Task.async(fn -> Goals.list_goals_by_user(user.id) end)

      user_challenges_task =
        Task.async(fn -> Challenges.list_participating_challenges(user.id) end)

      followers_count = Task.await(followers_count_task)
      following_count = Task.await(following_count_task)
      friends_count = Task.await(friends_count_task)
      user_goals = Task.await(user_goals_task)
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

      socket =
        socket
        |> assign(:user, user)
        |> assign(:user_level, user_level)
        |> assign(:followers_count, followers_count)
        |> assign(:following_count, following_count)
        |> assign(:friends_count, friends_count)
        |> assign(:user_goals, user_goals)
        |> assign(:user_challenges, user_challenges)
        |> assign(:is_following, is_following)
        |> assign(:friendship_status, friendship_status)
        |> assign(:can_follow, can_follow)
        |> assign(:can_view_private_content, can_view_private_content)
        |> assign(:editing_about, false)
        |> assign(:editing_bio, false)
        |> assign(:editing_avatar, false)
        |> assign(:show_report_modal, false)
        |> assign(:report_reason, "")
        |> assign(:report_description, "")
        |> assign(:about_form, to_form(%{"about" => user.about || ""}))
        |> assign(:bio_form, to_form(%{"bio" => user.bio || ""}))
        |> allow_upload(:avatar,
          accept: ~w(.jpg .jpeg .png),
          max_entries: 1,
          max_file_size: 5_000_000,
          auto_upload: true
        )

      socket =
        if can_view_private_content do
          assign_async(socket, :chart_stats, fn ->
            chart_data = HeadsUp.FeedService.get_user_activities_for_chart(user.id, 365)
            activity_summary = HeadsUp.ActivityService.get_user_activity_summary(user.id, 30)
            {:ok, %{chart_stats: %{chart_data: chart_data, activity_summary: activity_summary}}}
          end)
        else
          assign(socket, :chart_stats, nil)
        end

      {:ok, socket}
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

  def handle_event("edit_avatar", _params, socket) do
    if socket.assigns[:current_user] && socket.assigns.current_user.id == socket.assigns.user.id do
      socket =
        socket
        |> clear_avatar_uploads()
        |> assign(:editing_avatar, true)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("cancel_edit_avatar", _params, socket) do
    socket =
      socket
      |> clear_avatar_uploads()
      |> assign(:editing_avatar, false)

    {:noreply, socket}
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

  def handle_event("view_goal", %{"goal-id" => goal_id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/goals/#{goal_id}")}
  end

  def handle_event("view_user", %{"user-id" => user_id}, socket) do
    user = Accounts.get_user(user_id)

    if user do
      {:noreply, push_navigate(socket, to: ~p"/people/#{user.user_name}")}
    else
      {:noreply, socket}
    end
  end

  def handle_event("toggle_like", %{"goal-id" => _goal_id}, socket) do
    {:noreply, put_flash(socket, :info, "Like functionality coming soon!")}
  end

  def handle_event("toggle_subscribe", %{"goal-id" => _goal_id}, socket) do
    {:noreply, put_flash(socket, :info, "Subscribe functionality coming soon!")}
  end

  def handle_event("save_avatar", _params, socket) do
    if socket.assigns[:current_user] && socket.assigns.current_user.id == socket.assigns.user.id do
      case consume_uploaded_entries(socket, :avatar, fn %{path: path}, entry ->
             uploads_dir = Path.join(["priv", "static", "uploads"])
             File.mkdir_p!(uploads_dir)

             extension = avatar_file_extension(path, entry.client_name)

             filename =
               "avatar_#{socket.assigns.user.id}_#{System.unique_integer([:positive])}_#{System.os_time(:second)}#{extension}"

             dest_path = Path.join(uploads_dir, filename)

             case File.rename(path, dest_path) do
               :ok ->
                 {:ok, "/uploads/#{filename}"}

               {:error, _reason} ->
                 case File.cp(path, dest_path) do
                   :ok ->
                     {:ok, "/uploads/#{filename}"}

                   {:error, reason} ->
                     {:error, "Failed to save avatar: #{inspect(reason)}"}
                 end
             end
           end) do
        [image_path] when is_binary(image_path) ->
          case Accounts.update_user(socket.assigns.user, %{image_path: image_path}) do
            {:ok, updated_user} ->
              socket =
                socket
                |> assign(:user, updated_user)
                |> assign(:editing_avatar, false)
                |> put_flash(:info, "Avatar updated successfully")

              {:noreply, socket}

            {:error, _changeset} ->
              {:noreply, put_flash(socket, :error, "Failed to update avatar")}
          end

        [] ->
          {:noreply, put_flash(socket, :error, "Please select an image file")}

        [error] ->
          {:noreply, put_flash(socket, :error, error)}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("validate_avatar", _params, socket) do
    {:noreply, socket}
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

  defp avatar_file_extension(temp_path, client_name) do
    client_extension = client_name |> to_string() |> Path.extname() |> String.downcase()

    cond do
      client_extension in [".jpg", ".jpeg", ".png"] -> client_extension
      true -> temp_path |> Path.extname() |> String.downcase()
    end
  end

  defp clear_avatar_uploads(socket) do
    entries = socket.assigns.uploads.avatar.entries

    Enum.reduce(entries, socket, fn entry, acc ->
      cancel_upload(acc, :avatar, entry.ref)
    end)
  end

  defp upload_error_to_string(:too_large), do: "File is too large. Max size is 5MB."
  defp upload_error_to_string(:not_accepted), do: "Only PNG, JPG, and JPEG files are allowed."
  defp upload_error_to_string(:too_many_files), do: "Please upload only one image."
  defp upload_error_to_string(_), do: "Upload failed. Please try again."

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
    ~H"""
    <div class="flex gap-0 h-full">
      <%!-- Center Content --%>
      <div class="flex-grow min-w-0 p-5 sm:p-8 lg:p-10 overflow-y-auto custom-scrollbar">
        <%!-- Profile Hero Card --%>
        <div class="relative overflow-hidden bg-gradient-to-r from-blue-600 to-indigo-600 rounded-[40px] shadow-lg p-8 sm:p-10 lg:p-12 mb-8">
          <%!-- Background decoration --%>
          <div class="absolute top-0 right-0 w-64 h-64 opacity-10">
            <.icon name="hero-user" class="w-64 h-64 text-white" />
          </div>

          <%= if !@can_view_private_content do %>
            <%!-- Private Profile View --%>
            <div class="relative z-10 flex flex-col items-center text-center py-4">
              <%!-- Lock Icon instead of Avatar --%>
              <div class="w-28 h-28 sm:w-32 sm:h-32 rounded-[28px] bg-white/15 backdrop-blur-sm border-4 border-white/30 flex items-center justify-center mb-5">
                <.icon name="hero-lock-closed-solid" class="w-14 h-14 text-white/70" />
              </div>

              <h1 class="text-2xl sm:text-3xl lg:text-4xl font-extrabold text-white mb-2">
                {@user.name || "Anonymous"}
              </h1>

              <span class="inline-flex items-center gap-2 px-4 py-2 bg-white/15 backdrop-blur-sm text-white/90 text-sm font-bold rounded-full mb-4">
                <.icon name="hero-lock-closed" class="w-4 h-4" /> Private Person
              </span>

              <p class="text-blue-200 text-base max-w-sm">
                This profile is private. Send a friend request to connect.
              </p>

              <%!-- Action Buttons for private profiles --%>
              <%= if @current_user && @current_user.id != @user.id do %>
                <div class="flex flex-wrap gap-3 mt-6 justify-center">
                  <%= case @friendship_status do %>
                    <% :none -> %>
                      <button
                        phx-click="send_friend_request"
                        class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm bg-white text-blue-600 hover:scale-105 transition-transform shadow-lg"
                      >
                        <.icon name="hero-heart" class="w-4 h-4" />
                        <span class="truncate">Add Friend</span>
                      </button>
                    <% :request_sent -> %>
                      <button
                        phx-click="cancel_friend_request"
                        data-confirm="Are you sure you want to cancel this friend request?"
                        class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm bg-amber-500/80 text-white hover:bg-amber-500 transition-colors"
                      >
                        <.icon name="hero-clock" class="w-4 h-4" />
                        <span class="truncate">Cancel Request</span>
                      </button>
                    <% :request_received -> %>
                      <button
                        phx-click="accept_friend_request"
                        class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm bg-white text-blue-600 hover:scale-105 transition-transform shadow-lg"
                      >
                        <.icon name="hero-check" class="w-4 h-4" />
                        <span class="truncate">Accept</span>
                      </button>
                      <button
                        phx-click="decline_friend_request"
                        class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm bg-white/20 text-white border border-white/30 hover:bg-red-500/50 transition-colors"
                      >
                        <.icon name="hero-x-mark" class="w-4 h-4" />
                        <span class="truncate">Decline</span>
                      </button>
                    <% :friends -> %>
                      <button
                        phx-click="start_message"
                        class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm bg-white text-blue-600 hover:scale-105 transition-transform shadow-lg"
                      >
                        <.icon name="hero-chat-bubble-left-right" class="w-4 h-4" />
                        <span class="truncate">Message</span>
                      </button>
                      <button
                        phx-click="remove_friend"
                        data-confirm="Are you sure you want to remove this friend?"
                        class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm bg-white/20 text-white border border-white/30 hover:bg-red-500/50 transition-colors"
                      >
                        <.icon name="hero-user-minus" class="w-4 h-4" />
                        <span class="truncate">Remove Friend</span>
                      </button>
                  <% end %>
                </div>
              <% end %>
            </div>
          <% else %>
            <%!-- Normal Profile View --%>
            <div class="relative z-10 flex flex-col sm:flex-row items-center gap-6 sm:gap-8">
              <%!-- Avatar --%>
              <div class="relative group flex-shrink-0">
                <div class="border-4 border-white/30 shadow-xl rounded-[28px] overflow-hidden">
                  <HeadsUpWeb.Components.UI.Avatar.avatar
                    name={@user.name || @user.user_name || "U"}
                    src={get_user_avatar(@user)}
                    size={:xxl}
                    rounded={:xxl}
                  />
                </div>
                <%= if @current_user && @current_user.id == @user.id && !@editing_avatar do %>
                  <button
                    phx-click="edit_avatar"
                    class="absolute inset-0 flex items-center justify-center bg-black/50 rounded-[28px] opacity-0 group-hover:opacity-100 transition-opacity"
                  >
                    <.icon name="hero-camera" class="w-8 h-8 text-white" />
                  </button>
                <% end %>
              </div>

              <%!-- User Info --%>
              <div class="flex-1 text-center sm:text-left">
                <h1 class="text-2xl sm:text-3xl lg:text-4xl font-extrabold text-white mb-1">
                  {@user.name || "Anonymous"}
                </h1>
                <%= if @user.user_name do %>
                  <p class="text-blue-200 text-lg font-medium mb-3">@{@user.user_name}</p>
                <% end %>

                <%!-- Bio (inline editable) --%>
                <%= if @editing_bio do %>
                  <.form for={@bio_form} phx-submit="save_bio" class="space-y-2 max-w-md">
                    <input
                      type="text"
                      name="bio"
                      value={@user.bio}
                      class="w-full px-4 py-2 bg-white/20 backdrop-blur-sm text-white placeholder:text-blue-200 rounded-xl border border-white/30 focus:outline-none focus:ring-2 focus:ring-white/50"
                      placeholder="Short bio..."
                      maxlength="100"
                    />
                    <div class="flex gap-2">
                      <button
                        type="submit"
                        class="px-4 py-1.5 bg-white text-blue-600 rounded-xl font-bold text-sm hover:scale-105 transition-transform"
                      >
                        Save
                      </button>
                      <button
                        type="button"
                        phx-click="cancel_edit_bio"
                        class="px-4 py-1.5 bg-white/20 text-white rounded-xl font-bold text-sm hover:bg-white/30 transition-colors"
                      >
                        Cancel
                      </button>
                    </div>
                  </.form>
                <% else %>
                  <div class="group relative inline-block">
                    <p class="text-blue-100 text-base max-w-md">
                      {@user.bio || "No bio yet"}
                    </p>
                    <%= if @current_user && @current_user.id == @user.id do %>
                      <button
                        phx-click="edit_bio"
                        class="absolute -right-6 top-0 opacity-0 group-hover:opacity-100 transition-opacity"
                      >
                        <.icon
                          name="hero-pencil-square"
                          class="w-4 h-4 text-blue-200 hover:text-white"
                        />
                      </button>
                    <% end %>
                  </div>
                <% end %>

                <%!-- Stats Row --%>
                <div class="flex gap-6 mt-4 justify-center sm:justify-start">
                  <p class="text-white text-sm font-medium">
                    <span class="font-bold">{@followers_count}</span> followers
                  </p>
                  <p class="text-white text-sm font-medium">
                    <span class="font-bold">{@following_count}</span> following
                  </p>
                  <p class="text-white text-sm font-medium">
                    <span class="font-bold">{@friends_count}</span> friends
                  </p>
                </div>
              </div>
            </div>

            <%!-- Privacy Toggle (owner only) --%>
            <%= if @current_user && @current_user.id == @user.id do %>
              <div class="relative z-10 flex flex-wrap gap-3 mt-6 justify-center sm:justify-start">
                <button
                  phx-click="cycle_privacy"
                  class="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl font-bold text-sm bg-white/20 text-white border border-white/30 hover:bg-white/30 transition-colors backdrop-blur-sm"
                >
                  <.icon name={privacy_icon(@user.privacy)} class="w-4 h-4" />
                  <span>{privacy_label(@user.privacy)}</span>
                  <.icon name="hero-chevron-right" class="w-3.5 h-3.5 text-blue-200" />
                </button>
              </div>
            <% end %>

            <%!-- Action Buttons (inside hero) --%>
            <%= if @current_user && @current_user.id != @user.id do %>
              <div class="relative z-10 flex flex-wrap gap-3 mt-6 justify-center sm:justify-start">
                <%= if @can_follow do %>
                  <button
                    phx-click="toggle_follow"
                    class={[
                      "inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm transition-all",
                      if(@is_following,
                        do: "bg-white/20 text-white border border-white/30 hover:bg-white/30",
                        else: "bg-white text-blue-600 hover:scale-105 shadow-lg"
                      )
                    ]}
                  >
                    <.icon
                      name={if @is_following, do: "hero-user-minus", else: "hero-user-plus"}
                      class="w-4 h-4"
                    />
                    <span class="truncate">{if @is_following, do: "Unfollow", else: "Follow"}</span>
                  </button>
                <% end %>

                <%!-- Message button (disabled for non-friends) --%>
                <%= if @friendship_status != :friends do %>
                  <button
                    disabled
                    class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm bg-white/10 text-white/40 border border-white/20 cursor-not-allowed"
                    title="You must be friends to message"
                  >
                    <.icon name="hero-chat-bubble-left-right" class="w-4 h-4" />
                    <span class="truncate">Message</span>
                  </button>
                <% end %>

                <%= case @friendship_status do %>
                  <% :none -> %>
                    <button
                      phx-click="send_friend_request"
                      class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm bg-gradient-to-r from-green-500 to-emerald-600 text-white hover:scale-105 transition-transform shadow-lg"
                    >
                      <.icon name="hero-heart" class="w-4 h-4" />
                      <span class="truncate">Add Friend</span>
                    </button>
                  <% :request_sent -> %>
                    <button
                      phx-click="cancel_friend_request"
                      data-confirm="Are you sure you want to cancel this friend request?"
                      class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm bg-amber-500/80 text-white hover:bg-amber-500 transition-colors"
                    >
                      <.icon name="hero-clock" class="w-4 h-4" />
                      <span class="truncate">Cancel Request</span>
                    </button>
                  <% :request_received -> %>
                    <button
                      phx-click="accept_friend_request"
                      class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm bg-gradient-to-r from-green-500 to-emerald-600 text-white hover:scale-105 transition-transform shadow-lg"
                    >
                      <.icon name="hero-check" class="w-4 h-4" />
                      <span class="truncate">Accept</span>
                    </button>
                    <button
                      phx-click="decline_friend_request"
                      class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm bg-white/20 text-white border border-white/30 hover:bg-red-500/50 transition-colors"
                    >
                      <.icon name="hero-x-mark" class="w-4 h-4" />
                      <span class="truncate">Decline</span>
                    </button>
                  <% :friends -> %>
                    <button
                      phx-click="start_message"
                      class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm bg-white text-blue-600 hover:scale-105 transition-transform shadow-lg"
                    >
                      <.icon name="hero-chat-bubble-left-right" class="w-4 h-4" />
                      <span class="truncate">Message</span>
                    </button>
                    <button
                      phx-click="remove_friend"
                      data-confirm="Are you sure you want to remove this friend?"
                      class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm bg-white/20 text-white border border-white/30 hover:bg-red-500/50 transition-colors"
                    >
                      <.icon name="hero-user-minus" class="w-4 h-4" />
                      <span class="truncate">Remove Friend</span>
                    </button>
                <% end %>

                <%!-- Report User --%>
                <button
                  phx-click="show_report_modal"
                  class="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm bg-white/20 text-white border border-white/30 hover:bg-red-500/50 transition-colors"
                  title="Report user"
                >
                  <.icon name="hero-flag" class="w-4 h-4" />
                  <span class="truncate">Report</span>
                </button>
              </div>
            <% end %>
          <% end %>
        </div>

        <%!-- Avatar Upload Modal --%>
        <%= if @editing_avatar do %>
          <div class="bg-white rounded-[32px] shadow-sm p-8 mb-8">
            <h4 class="text-lg font-extrabold text-slate-900 mb-4">Change Avatar</h4>
            <form phx-submit="save_avatar" phx-change="validate_avatar">
              <div class="space-y-4">
                <div class="flex items-center justify-center w-full">
                  <div
                    phx-drop-target={@uploads.avatar.ref}
                    class="relative flex flex-col items-center justify-center w-full h-32 border-2 border-slate-200 border-dashed rounded-2xl bg-slate-50 hover:bg-slate-100 transition-colors"
                  >
                    <div class="flex flex-col items-center justify-center pt-5 pb-6">
                      <.icon name="hero-cloud-arrow-up" class="w-8 h-8 text-slate-400 mb-3" />
                      <p class="mb-1 text-sm text-slate-600">
                        <span class="font-bold">Click to upload</span> or drag and drop
                      </p>
                      <p class="text-xs text-slate-400">PNG, JPG or JPEG (MAX. 5MB)</p>
                    </div>
                    <.live_file_input
                      upload={@uploads.avatar}
                      id="avatar-upload"
                      class="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                    />
                  </div>
                </div>

                <%= for entry <- @uploads.avatar.entries do %>
                  <div class="flex items-center gap-3">
                    <div class="flex-1 bg-slate-200 rounded-full h-2">
                      <div
                        class="bg-gradient-to-r from-blue-500 to-indigo-600 h-2 rounded-full transition-all duration-300"
                        style={"width: #{entry.progress}%"}
                      >
                      </div>
                    </div>
                    <span class="text-sm text-slate-600 font-medium">{entry.progress}%</span>
                  </div>

                  <%= for err <- upload_errors(@uploads.avatar, entry) do %>
                    <p class="text-sm text-red-600">{upload_error_to_string(err)}</p>
                  <% end %>
                <% end %>

                <%= for err <- upload_errors(@uploads.avatar) do %>
                  <p class="text-sm text-red-600">{upload_error_to_string(err)}</p>
                <% end %>

                <div class="flex gap-3">
                  <button
                    type="submit"
                    class="inline-flex items-center gap-2 bg-gradient-to-r from-blue-500 to-indigo-600 text-white px-6 py-3 rounded-xl font-bold text-sm hover:scale-105 transition-transform"
                    disabled={Enum.empty?(@uploads.avatar.entries)}
                  >
                    <.icon name="hero-check" class="w-4 h-4" /> Save Avatar
                  </button>
                  <button
                    type="button"
                    phx-click="cancel_edit_avatar"
                    class="inline-flex items-center gap-2 bg-slate-100 text-slate-700 px-6 py-3 rounded-xl font-bold text-sm hover:bg-slate-200 transition-colors"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            </form>
          </div>
        <% end %>

        <%= if @can_view_private_content do %>
          <%!-- About Section --%>
          <div class="bg-white rounded-[32px] shadow-sm p-8 mb-6">
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-xl font-extrabold text-slate-900 flex items-center gap-2">
                <.icon name="hero-information-circle" class="w-5 h-5 text-blue-600" /> About
              </h2>
              <%= if @current_user && @current_user.id == @user.id && !@editing_about do %>
                <button
                  phx-click="edit_about"
                  class="text-blue-600 hover:text-blue-700 text-sm font-bold"
                >
                  Edit
                </button>
              <% end %>
            </div>

            <%= if @editing_about do %>
              <.form for={@about_form} phx-submit="save_about" class="space-y-4">
                <textarea
                  name="about"
                  rows="4"
                  class="w-full px-4 py-3 bg-slate-50 border-0 rounded-2xl focus:ring-2 focus:ring-blue-500 text-slate-900 placeholder:text-slate-400"
                  placeholder="Tell us about yourself..."
                ><%= @user.about %></textarea>
                <div class="flex gap-3">
                  <button
                    type="submit"
                    class="inline-flex items-center gap-2 bg-gradient-to-r from-blue-500 to-indigo-600 text-white px-6 py-3 rounded-xl font-bold text-sm hover:scale-105 transition-transform"
                  >
                    Save
                  </button>
                  <button
                    type="button"
                    phx-click="cancel_edit_about"
                    class="inline-flex items-center gap-2 bg-slate-100 text-slate-700 px-6 py-3 rounded-xl font-bold text-sm hover:bg-slate-200 transition-colors"
                  >
                    Cancel
                  </button>
                </div>
              </.form>
            <% else %>
              <p class="text-slate-600 text-base leading-relaxed whitespace-pre-wrap">
                {@user.about || "No information provided yet."}
              </p>
            <% end %>
          </div>

          <%!-- Level Section --%>
          <div class="bg-white rounded-[32px] shadow-sm p-8 mb-6">
            <h2 class="text-xl font-extrabold text-slate-900 flex items-center gap-2 mb-4">
              <.icon name="hero-arrow-trending-up" class="w-5 h-5 text-blue-600" /> Level
            </h2>
            <div class="flex flex-col gap-3">
              <div class="flex justify-between items-center">
                <div class="flex items-center gap-2">
                  <span class="inline-flex items-center gap-1 px-3 py-1 bg-indigo-50 text-indigo-700 text-sm font-bold rounded-full">
                    <.icon name="hero-star-solid" class="w-4 h-4" /> Level {@user_level}
                  </span>
                </div>
                <p class="text-sm text-slate-500 font-medium">
                  {get_xp_to_next_level(@user_level)} XP to next level
                </p>
              </div>
              <div class="w-full bg-slate-100 rounded-full h-3">
                <div
                  class="h-3 rounded-full bg-gradient-to-r from-blue-500 to-indigo-600 transition-all duration-500"
                  style={"width: #{get_level_progress(@user_level)}%;"}
                >
                </div>
              </div>
              <div class="flex justify-between text-xs text-slate-500 font-medium">
                <p>{get_current_level_xp(@user_level)} XP</p>
                <p>{get_next_level_xp(@user_level)} XP</p>
              </div>
            </div>
          </div>

          <%!-- Goals Section --%>
          <div class="bg-white rounded-[32px] shadow-sm p-8 mb-6">
            <h2 class="text-xl font-extrabold text-slate-900 flex items-center gap-2 mb-6">
              <.icon name="hero-flag" class="w-5 h-5 text-blue-600" /> Goals ({length(@user_goals)})
            </h2>
            <%= if Enum.empty?(@user_goals) do %>
              <div class="text-center py-8">
                <div class="w-14 h-14 rounded-2xl bg-slate-50 flex items-center justify-center mx-auto mb-3">
                  <.icon name="hero-flag" class="w-7 h-7 text-slate-400" />
                </div>
                <p class="text-slate-500 font-medium">No goals yet.</p>
              </div>
            <% else %>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div :for={goal <- @user_goals}>
                  <.goal_card
                    goal={goal}
                    show_category={true}
                    show_creator={false}
                    clickable={true}
                    current_user_id={if @current_user, do: @current_user.id, else: nil}
                  />
                </div>
              </div>
            <% end %>
          </div>

          <%!-- Challenges Section --%>
          <div class="bg-white rounded-[32px] shadow-sm p-8 mb-6">
            <h2 class="text-xl font-extrabold text-slate-900 flex items-center gap-2 mb-6">
              <.icon name="hero-bolt" class="w-5 h-5 text-indigo-600" />
              Challenges ({length(@user_challenges)})
            </h2>
            <%= if Enum.empty?(@user_challenges) do %>
              <div class="text-center py-8">
                <div class="w-14 h-14 rounded-2xl bg-slate-50 flex items-center justify-center mx-auto mb-3">
                  <.icon name="hero-bolt" class="w-7 h-7 text-slate-400" />
                </div>
                <p class="text-slate-500 font-medium">No challenges yet.</p>
              </div>
            <% else %>
              <div class="grid grid-cols-1 gap-4">
                <.link
                  :for={challenge <- @user_challenges}
                  navigate={~p"/challenges/#{challenge.id}"}
                  class="block group"
                >
                  <div class="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl hover:bg-slate-100 transition-colors">
                    <div class={[
                      "w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0",
                      case challenge.status do
                        :active -> "bg-gradient-to-br from-blue-500 to-indigo-600"
                        :completed -> "bg-gradient-to-br from-green-500 to-emerald-600"
                        :failed -> "bg-gradient-to-br from-slate-400 to-slate-500"
                        _ -> "bg-gradient-to-br from-blue-500 to-indigo-600"
                      end
                    ]}>
                      <.icon
                        name={challenge_status_icon(challenge.status)}
                        class="w-6 h-6 text-white/90"
                      />
                    </div>
                    <div class="flex-1 min-w-0">
                      <h3 class="text-sm font-extrabold text-slate-900 truncate group-hover:text-blue-600 transition-colors">
                        {challenge.title}
                      </h3>
                      <div class="flex items-center gap-3 mt-1">
                        <span class={[
                          "px-2 py-0.5 text-xs font-bold rounded-full",
                          case challenge.status do
                            :active -> "bg-blue-50 text-blue-600"
                            :completed -> "bg-green-50 text-green-600"
                            :failed -> "bg-slate-100 text-slate-500"
                            _ -> "bg-blue-50 text-blue-600"
                          end
                        ]}>
                          {challenge.status |> to_string() |> String.capitalize()}
                        </span>
                        <%= if challenge.category do %>
                          <span class="text-xs text-slate-400">{challenge.category.name}</span>
                        <% end %>
                      </div>
                    </div>
                    <.icon name="hero-chevron-right" class="w-4 h-4 text-slate-400 flex-shrink-0" />
                  </div>
                </.link>
              </div>
            <% end %>
          </div>
        <% else %>
          <%!-- Private Profile Content Placeholder --%>
          <div class="bg-white rounded-[32px] shadow-sm p-10 mb-6 text-center">
            <div class="w-16 h-16 rounded-2xl bg-slate-100 flex items-center justify-center mx-auto mb-4">
              <.icon name="hero-lock-closed" class="w-8 h-8 text-slate-400" />
            </div>
            <h3 class="text-lg font-extrabold text-slate-900 mb-2">Private Profile</h3>
            <p class="text-slate-500 text-sm max-w-sm mx-auto">
              <%= if @user.privacy == "private" do %>
                This user's profile is private. Send a friend request to see their content.
              <% else %>
                This user shares their profile with friends only. Send a friend request to connect.
              <% end %>
            </p>
          </div>
        <% end %>

        <%!-- Commitment Chart Section --%>
        <div class="bg-white rounded-[32px] shadow-sm p-8 mb-6">
          <h2 class="text-xl font-extrabold text-slate-900 flex items-center gap-2 mb-6">
            <.icon name="hero-chart-bar" class="w-5 h-5 text-blue-600" /> Commitment Chart
          </h2>
          <%= if @can_view_private_content do %>
            <.async_result :let={stats} assign={@chart_stats}>
              <:loading>
                <div class="flex flex-col items-center justify-center p-12 bg-slate-50 rounded-2xl">
                  <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mb-2">
                  </div>
                  <p class="text-sm text-slate-500">Loading activity data...</p>
                </div>
              </:loading>
              <:failed :let={_reason}>
                <div class="p-6 bg-red-50 text-red-600 rounded-2xl text-center">
                  <.icon name="hero-exclamation-triangle" class="w-6 h-6 mx-auto mb-2" />
                  <p class="font-medium">Failed to load activity data.</p>
                </div>
              </:failed>
              <.commitment_chart
                chart_data={stats.chart_data}
                activity_summary={stats.activity_summary}
                user={@user}
                user_level={@user_level}
              />
            </.async_result>
          <% else %>
            <%!-- CRITICAL: exact class string preserved for test compatibility --%>
            <div class="bg-gray-100 p-4 rounded-lg border border-gray-200 text-center">
              <div class="text-slate-600">
                <.icon name="hero-lock-closed" class="w-8 h-8 mx-auto mb-2 text-slate-400" />
                <p class="text-sm font-medium">Chart is private</p>
                <p class="text-xs text-slate-500 mt-1">
                  <%= if @user.privacy == "private" do %>
                    This user's commitment chart is private
                  <% else %>
                    This user shares their commitment chart with friends only
                  <% end %>
                </p>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <%!-- Right Sidebar (Desktop Only) --%>
      <div class="hidden xl:flex flex-col w-[420px] flex-shrink-0 bg-white border-l border-slate-100 p-8 overflow-y-auto custom-scrollbar gap-10">
        <%!-- Profile Summary --%>
        <div>
          <h3 class="text-lg font-extrabold text-slate-900 mb-4">Stats</h3>
          <div class="space-y-3">
            <div class="flex items-center justify-between p-4 bg-slate-50 rounded-2xl">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-xl bg-sky-50 flex items-center justify-center">
                  <.icon name="hero-users" class="w-5 h-5 text-blue-600" />
                </div>
                <p class="text-sm font-bold text-slate-900">followers</p>
              </div>
              <span class="text-xl font-extrabold text-slate-900">{@followers_count}</span>
            </div>
            <div class="flex items-center justify-between p-4 bg-slate-50 rounded-2xl">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-xl bg-green-50 flex items-center justify-center">
                  <.icon name="hero-eye" class="w-5 h-5 text-green-600" />
                </div>
                <p class="text-sm font-bold text-slate-900">following</p>
              </div>
              <span class="text-xl font-extrabold text-slate-900">{@following_count}</span>
            </div>
            <div class="flex items-center justify-between p-4 bg-slate-50 rounded-2xl">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-xl bg-indigo-50 flex items-center justify-center">
                  <.icon name="hero-heart" class="w-5 h-5 text-indigo-600" />
                </div>
                <p class="text-sm font-bold text-slate-900">friends</p>
              </div>
              <span class="text-xl font-extrabold text-slate-900">{@friends_count}</span>
            </div>
            <div class="flex items-center justify-between p-4 bg-slate-50 rounded-2xl">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-xl bg-amber-50 flex items-center justify-center">
                  <.icon name="hero-flag" class="w-5 h-5 text-amber-600" />
                </div>
                <p class="text-sm font-bold text-slate-900">goals</p>
              </div>
              <span class="text-xl font-extrabold text-slate-900">{length(@user_goals)}</span>
            </div>
            <div class="flex items-center justify-between p-4 bg-slate-50 rounded-2xl">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-xl bg-indigo-50 flex items-center justify-center">
                  <.icon name="hero-bolt" class="w-5 h-5 text-indigo-600" />
                </div>
                <p class="text-sm font-bold text-slate-900">challenges</p>
              </div>
              <span class="text-xl font-extrabold text-slate-900">{length(@user_challenges)}</span>
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
                <.icon name="hero-users" class="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <p class="text-sm font-bold text-slate-900">All Members</p>
                <p class="text-xs text-slate-500">Browse the community</p>
              </div>
              <.icon name="hero-chevron-right" class="w-4 h-4 text-slate-400 ml-auto" />
            </.link>
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
          </div>
        </div>

        <%!-- Level Badge --%>
        <div class="relative overflow-hidden bg-gradient-to-br from-blue-600 to-indigo-700 rounded-[32px] p-8">
          <div class="relative z-10">
            <div class="w-14 h-14 rounded-2xl bg-white/20 flex items-center justify-center mb-4">
              <.icon name="hero-star" class="w-7 h-7 text-white" />
            </div>
            <h4 class="text-xl font-extrabold text-white mb-2">Level {@user_level}</h4>
            <p class="text-blue-100 text-sm mb-4">
              {get_xp_to_next_level(@user_level)} XP until next level
            </p>
            <div class="w-full bg-white/20 rounded-full h-2">
              <div
                class="h-2 rounded-full bg-white transition-all duration-500"
                style={"width: #{get_level_progress(@user_level)}%;"}
              >
              </div>
            </div>
          </div>
          <div class="absolute -bottom-4 -right-4 opacity-10">
            <.icon name="hero-trophy" class="w-32 h-32 text-white" />
          </div>
        </div>
      </div>
    </div>

    <%!-- Report Modal --%>
    <%= if @show_report_modal do %>
      <div class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4 z-50">
        <div class="bg-white rounded-[32px] shadow-2xl max-w-md w-full p-8">
          <div class="flex items-center gap-3 mb-6">
            <div class="w-12 h-12 bg-red-50 rounded-xl flex items-center justify-center">
              <.icon name="hero-flag" class="w-6 h-6 text-red-500" />
            </div>
            <h3 class="text-xl font-extrabold text-slate-900">Report User</h3>
          </div>

          <p class="text-sm text-slate-500 mb-6">
            Help us keep the community safe. Select a reason for your report.
          </p>

          <form phx-submit="submit_report">
            <div class="mb-4">
              <label class="block text-sm font-bold text-slate-700 mb-3">Reason *</label>
              <div class="space-y-2">
                <%= for reason <- HeadsUp.Reports.Report.reasons() do %>
                  <label class={"flex items-center gap-3 p-3 rounded-xl cursor-pointer transition-colors #{if @report_reason == reason, do: "bg-red-50 ring-2 ring-red-200", else: "bg-slate-50 hover:bg-slate-100"}"}>
                    <input
                      type="radio"
                      name="report_reason"
                      value={reason}
                      checked={@report_reason == reason}
                      phx-click="update_report_reason"
                      phx-value-report_reason={reason}
                      class="text-red-500 focus:ring-red-500"
                    />
                    <span class="text-sm font-medium text-slate-700 capitalize">{reason}</span>
                  </label>
                <% end %>
              </div>
            </div>

            <div class="mb-6">
              <label for="report_description" class="block text-sm font-bold text-slate-700 mb-2">
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
                class="w-full bg-slate-50 border-none rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-red-500 resize-none"
              ><%= @report_description %></textarea>
              <div class="text-xs text-slate-400 mt-1 text-right">
                {String.length(@report_description)}/500
              </div>
            </div>

            <div class="flex justify-end gap-3">
              <button
                type="button"
                phx-click="hide_report_modal"
                class="px-5 py-3 bg-slate-100 text-slate-600 rounded-xl text-sm font-bold hover:bg-slate-200 transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={@report_reason == ""}
                class="px-5 py-3 bg-red-500 text-white rounded-xl text-sm font-bold hover:bg-red-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
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

  # -- Helpers --

  defp get_xp_for_level(level) do
    level * 100
  end

  defp get_total_xp_for_level(level) do
    Enum.sum(1..level |> Enum.map(&get_xp_for_level/1))
  end

  defp get_current_level_xp(level) do
    if level <= 1 do
      0
    else
      get_total_xp_for_level(level - 1)
    end
  end

  defp get_next_level_xp(level) do
    get_total_xp_for_level(level)
  end

  defp get_xp_to_next_level(level) do
    get_xp_for_level(level)
  end

  defp get_level_progress(_level) do
    :rand.uniform(100)
  end

  defp challenge_status_icon(:active), do: "hero-bolt"
  defp challenge_status_icon(:completed), do: "hero-trophy"
  defp challenge_status_icon(:failed), do: "hero-x-circle"
  defp challenge_status_icon(_), do: "hero-bolt"
end
