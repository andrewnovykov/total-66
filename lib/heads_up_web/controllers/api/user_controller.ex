defmodule HeadsUpWeb.Api.UserController do
  use HeadsUpWeb, :controller

  alias HeadsUp.Accounts

  action_fallback HeadsUpWeb.FallbackController

  # GET /api/users - List users (public profiles)
  def index(conn, params) do
    users =
      Accounts.list_users()
      |> Enum.filter(&(&1.status == :active))
      |> paginate(params)

    conn
    |> put_status(:ok)
    |> render(:index, users: users)
  end

  # GET /api/users/:id - Show user profile
  def show(conn, %{"id" => id}) do
    current_user_id = get_current_user_id(conn)

    case Integer.parse(id) do
      {user_id, _} ->
        case Accounts.get_user(user_id) do
          nil ->
            conn |> put_status(:not_found) |> render(:error, message: "User not found")

          user ->
            stats = Accounts.get_user_with_stats(user_id)

            conn
            |> put_status(:ok)
            |> render(:show, user: user, stats: stats, current_user_id: current_user_id)
        end

      :error ->
        conn |> put_status(:bad_request) |> render(:error, message: "Invalid user ID")
    end
  end

  # GET /api/users/username/:username - Show user by username
  def show_by_username(conn, %{"username" => username}) do
    current_user_id = get_current_user_id(conn)

    case Accounts.get_user_by_username(username) do
      nil ->
        conn |> put_status(:not_found) |> render(:error, message: "User not found")

      user ->
        stats = Accounts.get_user_with_stats(user.id)

        conn
        |> put_status(:ok)
        |> render(:show, user: user, stats: stats, current_user_id: current_user_id)
    end
  end

  # PUT /api/users/me - Update current user profile
  def update_profile(conn, %{"user" => user_params}) do
    current_user = conn.assigns[:current_user]

    if current_user do
      allowed = Map.take(user_params, ["name", "bio", "about"])

      case Accounts.update_user(current_user, allowed) do
        {:ok, updated_user} ->
          stats = Accounts.get_user_with_stats(updated_user.id)

          conn
          |> put_status(:ok)
          |> render(:show, user: updated_user, stats: stats, current_user_id: updated_user.id)

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(:changeset_error, changeset: changeset)
      end
    else
      conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
    end
  end

  # GET /api/users/:id/followers - List user's followers
  def followers(conn, %{"id" => id}) do
    case Integer.parse(id) do
      {user_id, _} ->
        followers = Accounts.list_followers(user_id)
        conn |> put_status(:ok) |> render(:users_list, users: followers)

      :error ->
        conn |> put_status(:bad_request) |> render(:error, message: "Invalid user ID")
    end
  end

  # GET /api/users/:id/following - List users being followed
  def following(conn, %{"id" => id}) do
    case Integer.parse(id) do
      {user_id, _} ->
        following = Accounts.list_following(user_id)
        conn |> put_status(:ok) |> render(:users_list, users: following)

      :error ->
        conn |> put_status(:bad_request) |> render(:error, message: "Invalid user ID")
    end
  end

  # POST /api/users/:id/follow - Follow a user
  def follow(conn, %{"id" => id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {user_id, _} ->
          case Accounts.follow_user(current_user_id, user_id) do
            {:ok, _} ->
              conn
              |> put_status(:ok)
              |> render(:action_success, message: "User followed successfully")

            {:error, :cannot_follow_self} ->
              conn
              |> put_status(:forbidden)
              |> render(:error, message: "You cannot follow yourself")

            {:error, :user_is_private} ->
              conn
              |> put_status(:forbidden)
              |> render(:error, message: "Cannot follow private user")

            {:error, :must_be_friends} ->
              conn
              |> put_status(:forbidden)
              |> render(:error, message: "Must be friends to follow this user")

            {:error, :user_not_found} ->
              conn
              |> put_status(:not_found)
              |> render(:error, message: "User not found")

            {:error, _} ->
              conn
              |> put_status(:unprocessable_entity)
              |> render(:error, message: "Failed to follow user")
          end

        :error ->
          conn
          |> put_status(:bad_request)
          |> render(:error, message: "Invalid user ID")
      end
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "Authentication required")
    end
  end

  # DELETE /api/users/:id/follow - Unfollow a user
  def unfollow(conn, %{"id" => id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {user_id, _} ->
          case Accounts.unfollow_user(current_user_id, user_id) do
            {:ok, _} ->
              conn
              |> put_status(:ok)
              |> render(:action_success, message: "User unfollowed successfully")

            {:error, _} ->
              conn
              |> put_status(:unprocessable_entity)
              |> render(:error, message: "Failed to unfollow user")
          end

        :error ->
          conn
          |> put_status(:bad_request)
          |> render(:error, message: "Invalid user ID")
      end
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "Authentication required")
    end
  end

  # POST /api/users/:id/friend-request - Send friend request
  def send_friend_request(conn, %{"id" => id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {friend_id, _} ->
          case Accounts.send_friend_request(current_user_id, friend_id) do
            {:ok, _} ->
              conn
              |> put_status(:ok)
              |> render(:action_success, message: "Friend request sent successfully")

            {:error, :cannot_friend_self} ->
              conn
              |> put_status(:forbidden)
              |> render(:error, message: "You cannot send friend request to yourself")

            {:error, :friendship_already_exists} ->
              conn
              |> put_status(:conflict)
              |> render(:error, message: "Friendship already exists")

            {:error, :user_not_found} ->
              conn
              |> put_status(:not_found)
              |> render(:error, message: "User not found")

            {:error, _} ->
              conn
              |> put_status(:unprocessable_entity)
              |> render(:error, message: "Failed to send friend request")
          end

        :error ->
          conn
          |> put_status(:bad_request)
          |> render(:error, message: "Invalid user ID")
      end
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "Authentication required")
    end
  end

  # POST /api/friend-requests/:id/accept - Accept friend request
  def accept_friend_request(conn, %{"id" => id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {friend_id, _} ->
          case Accounts.accept_friend_request(current_user_id, friend_id) do
            {:ok, _} ->
              conn
              |> put_status(:ok)
              |> render(:action_success, message: "Friend request accepted")

            {:error, :request_not_found} ->
              conn
              |> put_status(:not_found)
              |> render(:error, message: "Friend request not found")

            {:error, :request_not_pending} ->
              conn
              |> put_status(:conflict)
              |> render(:error, message: "Friend request is not pending")

            {:error, _} ->
              conn
              |> put_status(:unprocessable_entity)
              |> render(:error, message: "Failed to accept friend request")
          end

        :error ->
          conn
          |> put_status(:bad_request)
          |> render(:error, message: "Invalid user ID")
      end
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "Authentication required")
    end
  end

  # POST /api/friend-requests/:id/decline - Decline friend request
  def decline_friend_request(conn, %{"id" => id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {friend_id, _} ->
          case Accounts.decline_friend_request(current_user_id, friend_id) do
            {:ok, _} ->
              conn
              |> put_status(:ok)
              |> render(:action_success, message: "Friend request declined")

            {:error, :request_not_found} ->
              conn
              |> put_status(:not_found)
              |> render(:error, message: "Friend request not found")

            {:error, :request_not_pending} ->
              conn
              |> put_status(:conflict)
              |> render(:error, message: "Friend request is not pending")

            {:error, _} ->
              conn
              |> put_status(:unprocessable_entity)
              |> render(:error, message: "Failed to decline friend request")
          end

        :error ->
          conn
          |> put_status(:bad_request)
          |> render(:error, message: "Invalid user ID")
      end
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "Authentication required")
    end
  end

  # DELETE /api/friend-requests/:id - Cancel friend request
  def cancel_friend_request(conn, %{"id" => id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {friend_id, _} ->
          case Accounts.cancel_friend_request(current_user_id, friend_id) do
            {:ok, _} ->
              conn
              |> put_status(:ok)
              |> render(:action_success, message: "Friend request cancelled")

            {:error, :request_not_found} ->
              conn
              |> put_status(:not_found)
              |> render(:error, message: "Friend request not found")

            {:error, :cannot_cancel} ->
              conn
              |> put_status(:forbidden)
              |> render(:error, message: "Cannot cancel this friend request")

            {:error, _} ->
              conn
              |> put_status(:unprocessable_entity)
              |> render(:error, message: "Failed to cancel friend request")
          end

        :error ->
          conn
          |> put_status(:bad_request)
          |> render(:error, message: "Invalid user ID")
      end
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "Authentication required")
    end
  end

  # DELETE /api/friends/:id - Remove friend
  def remove_friend(conn, %{"id" => id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {friend_id, _} ->
          case Accounts.remove_friend(current_user_id, friend_id) do
            {:ok, _} ->
              conn
              |> put_status(:ok)
              |> render(:action_success, message: "Friend removed successfully")

            {:error, _} ->
              conn
              |> put_status(:unprocessable_entity)
              |> render(:error, message: "Failed to remove friend")
          end

        :error ->
          conn
          |> put_status(:bad_request)
          |> render(:error, message: "Invalid user ID")
      end
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "Authentication required")
    end
  end

  # GET /api/friend-requests - List incoming friend requests
  def list_friend_requests(conn, _params) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      requests = Accounts.list_friend_requests(current_user_id)

      conn
      |> put_status(:ok)
      |> render(:friend_requests, requests: requests)
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "Authentication required")
    end
  end

  # GET /api/friends - List friends
  def list_friends(conn, _params) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      friends = Accounts.list_friends(current_user_id)

      conn
      |> put_status(:ok)
      |> render(:friends, friends: friends)
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "Authentication required")
    end
  end

  # Private helper functions

  defp get_current_user_id(conn) do
    case conn.assigns[:current_user] do
      %{id: user_id} -> user_id
      _ -> nil
    end
  end

  defp paginate(items, params) do
    page = parse_int(params["page"], 1)
    per_page = parse_int(params["per_page"], 20) |> min(100)
    offset = (page - 1) * per_page

    items |> Enum.drop(offset) |> Enum.take(per_page)
  end

  defp parse_int(nil, default), do: default

  defp parse_int(str, default) do
    case Integer.parse(str) do
      {n, _} when n > 0 -> n
      _ -> default
    end
  end
end
