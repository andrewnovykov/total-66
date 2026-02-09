defmodule HeadsUpWeb.Api.ActivityController do
  use HeadsUpWeb, :controller

  alias HeadsUp.{ActivityService, FeedService}

  action_fallback HeadsUpWeb.FallbackController

  # GET /api/activities/:user_id - Get user's activity history
  def user_activities(conn, %{"user_id" => user_id} = params) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(user_id) do
        {target_user_id, _} ->
          # Check if current user can view this user's activities
          if can_view_activities?(current_user_id, target_user_id) do
            page = parse_page(params["page"])
            limit = parse_limit(params["limit"])

            activities = ActivityService.get_user_activities(target_user_id, page, limit)

            conn
            |> put_status(:ok)
            |> render(:activities, activities: activities)
          else
            conn
            |> put_status(:forbidden)
            |> render(:error, message: "Access denied")
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

  # GET /api/feed - Get user's social feed
  def user_feed(conn, params) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      page = parse_page(params["page"])
      limit = parse_limit(params["limit"])

      feed_items = FeedService.get_user_feed(current_user_id, page, limit)

      conn
      |> put_status(:ok)
      |> render(:feed, feed_items: feed_items)
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "Authentication required")
    end
  end

  # GET /api/chart/:user_id - Get commitment chart data
  def chart_data(conn, %{"user_id" => user_id} = params) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(user_id) do
        {target_user_id, _} ->
          # Check if current user can view this user's chart
          if can_view_activities?(current_user_id, target_user_id) do
            year = parse_year(params["year"])

            chart_data = FeedService.get_commitment_chart_data(target_user_id, year)

            conn
            |> put_status(:ok)
            |> render(:chart, chart_data: chart_data)
          else
            conn
            |> put_status(:forbidden)
            |> render(:error, message: "Access denied")
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

  # GET /api/user/:user_id/stats - Get user statistics
  def user_stats(conn, %{"user_id" => user_id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(user_id) do
        {target_user_id, _} ->
          if can_view_activities?(current_user_id, target_user_id) do
            stats = ActivityService.get_user_stats(target_user_id)

            conn
            |> put_status(:ok)
            |> render(:stats, stats: stats)
          else
            conn
            |> put_status(:forbidden)
            |> render(:error, message: "Access denied")
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

  # Private helper functions

  defp get_current_user_id(conn) do
    case conn.assigns[:current_user] do
      %{id: user_id} -> user_id
      _ -> nil
    end
  end

  defp can_view_activities?(current_user_id, target_user_id) do
    # Users can always view their own activities
    if current_user_id == target_user_id do
      true
    else
      # Check if users are friends or if target user is public
      # For now, we'll allow viewing if they're friends or following each other
      HeadsUp.Accounts.are_friends?(current_user_id, target_user_id) ||
        HeadsUp.Accounts.is_following?(current_user_id, target_user_id)
    end
  end

  defp parse_page(nil), do: 1

  defp parse_page(page_str) do
    case Integer.parse(page_str) do
      {page, _} when page > 0 -> page
      _ -> 1
    end
  end

  defp parse_limit(nil), do: 20

  defp parse_limit(limit_str) do
    case Integer.parse(limit_str) do
      {limit, _} when limit > 0 and limit <= 100 -> limit
      _ -> 20
    end
  end

  defp parse_year(nil) do
    Date.utc_today().year
  end

  defp parse_year(year_str) do
    case Integer.parse(year_str) do
      {year, _} when year >= 2020 and year <= 2030 -> year
      _ -> Date.utc_today().year
    end
  end
end
