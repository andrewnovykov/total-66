defmodule HeadsUpWeb.Api.GoalPostController do
  use HeadsUpWeb, :controller

  alias HeadsUp.{Goals, Repo}

  action_fallback HeadsUpWeb.FallbackController

  # GET /api/goals/:goal_id/posts
  def index(conn, %{"goal_id" => goal_id} = params) do
    current_user_id = get_current_user_id(conn)

    case Integer.parse(goal_id) do
      {id, _} ->
        case Goals.get_goal(id) do
          nil ->
            conn |> put_status(:not_found) |> render(:error, message: "Goal not found")

          _goal ->
            posts =
              Goals.list_goal_posts(id)
              |> Repo.preload([:user, :goal_post_likes])
              |> Enum.map(&Goals.add_post_like_info(&1, current_user_id))
              |> paginate(params)

            conn
            |> put_status(:ok)
            |> render(:index, posts: posts, current_user_id: current_user_id)
        end

      :error ->
        conn |> put_status(:bad_request) |> render(:error, message: "Invalid goal ID")
    end
  end

  # POST /api/goals/:goal_id/posts
  def create(conn, %{"goal_id" => goal_id, "post" => post_params}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(goal_id) do
        {id, _} ->
          case Goals.get_goal(id) do
            nil ->
              conn |> put_status(:not_found) |> render(:error, message: "Goal not found")

            goal ->
              post_params =
                Map.merge(post_params, %{
                  "goal_id" => goal.id,
                  "user_id" => current_user_id
                })

              case Goals.create_goal_post_with_ownership(post_params, current_user_id) do
                {:ok, post} ->
                  post = Repo.preload(post, [:user, :goal_post_likes])

                  conn
                  |> put_status(:created)
                  |> render(:show, post: post, current_user_id: current_user_id)

                {:error, :unauthorized} ->
                  conn
                  |> put_status(:forbidden)
                  |> render(:error, message: "You can only create posts on your own goals")

                {:error, changeset} ->
                  conn
                  |> put_status(:unprocessable_entity)
                  |> render(:changeset_error, changeset: changeset)
              end
          end

        :error ->
          conn |> put_status(:bad_request) |> render(:error, message: "Invalid goal ID")
      end
    else
      conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
    end
  end

  # PUT /api/goals/:goal_id/posts/:id
  def update(conn, %{"id" => id, "post" => post_params}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {post_id, _} ->
          post = Goals.list_goal_posts(0) |> Enum.find(&(&1.id == post_id))

          if post do
            case Goals.update_goal_post_with_ownership(post, post_params, current_user_id) do
              {:ok, updated_post} ->
                updated_post = Repo.preload(updated_post, [:user, :goal_post_likes])

                conn
                |> put_status(:ok)
                |> render(:show, post: updated_post, current_user_id: current_user_id)

              {:error, :unauthorized} ->
                conn
                |> put_status(:forbidden)
                |> render(:error, message: "You can only update your own posts")

              {:error, changeset} ->
                conn
                |> put_status(:unprocessable_entity)
                |> render(:changeset_error, changeset: changeset)
            end
          else
            conn |> put_status(:not_found) |> render(:error, message: "Post not found")
          end

        :error ->
          conn |> put_status(:bad_request) |> render(:error, message: "Invalid post ID")
      end
    else
      conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
    end
  end

  # DELETE /api/goals/:goal_id/posts/:id
  def delete(conn, %{"id" => id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {post_id, _} ->
          post = Goals.list_goal_posts(0) |> Enum.find(&(&1.id == post_id))

          if post do
            case Goals.delete_goal_post_with_ownership(post, current_user_id) do
              {:ok, _} ->
                conn
                |> put_status(:ok)
                |> render(:action_success, message: "Post deleted successfully")

              {:error, :unauthorized} ->
                conn
                |> put_status(:forbidden)
                |> render(:error, message: "You can only delete your own posts")

              {:error, _} ->
                conn
                |> put_status(:unprocessable_entity)
                |> render(:error, message: "Failed to delete post")
            end
          else
            conn |> put_status(:not_found) |> render(:error, message: "Post not found")
          end

        :error ->
          conn |> put_status(:bad_request) |> render(:error, message: "Invalid post ID")
      end
    else
      conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
    end
  end

  # POST /api/goals/:goal_id/posts/:id/like
  def like(conn, %{"id" => id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {post_id, _} ->
          case Goals.like_post(post_id, current_user_id) do
            {:ok, _} ->
              conn |> put_status(:ok) |> render(:action_success, message: "Post liked")

            {:error, _} ->
              conn
              |> put_status(:unprocessable_entity)
              |> render(:error, message: "Failed to like post")
          end

        :error ->
          conn |> put_status(:bad_request) |> render(:error, message: "Invalid post ID")
      end
    else
      conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
    end
  end

  # DELETE /api/goals/:goal_id/posts/:id/like
  def unlike(conn, %{"id" => id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {post_id, _} ->
          case Goals.unlike_post(post_id, current_user_id) do
            {:ok, _} ->
              conn |> put_status(:ok) |> render(:action_success, message: "Post unliked")

            {:error, _} ->
              conn
              |> put_status(:unprocessable_entity)
              |> render(:error, message: "Failed to unlike post")
          end

        :error ->
          conn |> put_status(:bad_request) |> render(:error, message: "Invalid post ID")
      end
    else
      conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
    end
  end

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
