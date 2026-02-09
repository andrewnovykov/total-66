defmodule HeadsUpWeb.Api.GoalCommentController do
  use HeadsUpWeb, :controller

  alias HeadsUp.{Goals, Repo}

  action_fallback HeadsUpWeb.FallbackController

  # GET /api/posts/:post_id/comments
  def index(conn, %{"post_id" => post_id} = params) do
    case Integer.parse(post_id) do
      {id, _} ->
        comments =
          Goals.list_comments(id)
          |> Repo.preload(:user)
          |> paginate(params)

        conn |> put_status(:ok) |> render(:index, comments: comments)

      :error ->
        conn |> put_status(:bad_request) |> render(:error, message: "Invalid post ID")
    end
  end

  # POST /api/posts/:post_id/comments
  def create(conn, %{"post_id" => post_id, "comment" => comment_params}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(post_id) do
        {id, _} ->
          attrs =
            Map.merge(comment_params, %{
              "goal_post_id" => id,
              "user_id" => current_user_id
            })

          case Goals.create_comment(attrs) do
            {:ok, comment} ->
              comment = Repo.preload(comment, :user)
              conn |> put_status(:created) |> render(:show, comment: comment)

            {:error, changeset} ->
              conn
              |> put_status(:unprocessable_entity)
              |> render(:changeset_error, changeset: changeset)
          end

        :error ->
          conn |> put_status(:bad_request) |> render(:error, message: "Invalid post ID")
      end
    else
      conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
    end
  end

  # DELETE /api/posts/:post_id/comments/:id
  def delete(conn, %{"id" => id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {comment_id, _} ->
          comment = Goals.get_comment!(comment_id)

          case Goals.delete_comment(comment, current_user_id) do
            {:ok, _} ->
              conn |> put_status(:ok) |> render(:action_success, message: "Comment deleted")

            {:error, :unauthorized} ->
              conn
              |> put_status(:forbidden)
              |> render(:error, message: "You can only delete your own comments")

            {:error, _} ->
              conn
              |> put_status(:unprocessable_entity)
              |> render(:error, message: "Failed to delete comment")
          end

        :error ->
          conn |> put_status(:bad_request) |> render(:error, message: "Invalid comment ID")
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
