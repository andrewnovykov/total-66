defmodule HeadsUpWeb.Api.ReportController do
  use HeadsUpWeb, :controller

  alias HeadsUp.Reports

  action_fallback HeadsUpWeb.FallbackController

  # POST /api/users/:id/report
  def report_user(conn, %{"id" => id} = params) do
    reporter_id = get_current_user_id(conn)

    with {reported_user_id, _} <- Integer.parse(id) do
      attrs = %{
        reason: params["reason"],
        description: params["description"]
      }

      case Reports.report_user(reported_user_id, reporter_id, attrs) do
        {:ok, report} ->
          conn
          |> put_status(:created)
          |> render(:show, report: report)

        {:error, :not_found} ->
          conn
          |> put_status(:not_found)
          |> render(:error, message: "User not found")

        {:error, :already_reported} ->
          conn
          |> put_status(:conflict)
          |> render(:error, message: "You have already reported this user")

        {:error, :cannot_report_own} ->
          conn
          |> put_status(:forbidden)
          |> render(:error, message: "You cannot report yourself")

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(:error, changeset: changeset)
      end
    else
      :error ->
        conn
        |> put_status(:bad_request)
        |> render(:error, message: "Invalid user ID")
    end
  end

  # POST /api/challenges/:id/report
  def report_challenge(conn, %{"id" => id} = params) do
    user_id = get_current_user_id(conn)

    with {challenge_id, _} <- Integer.parse(id) do
      attrs = %{
        reason: params["reason"],
        description: params["description"]
      }

      case Reports.report_challenge(challenge_id, user_id, attrs) do
        {:ok, report} ->
          conn
          |> put_status(:created)
          |> render(:show, report: report)

        {:error, :not_found} ->
          conn
          |> put_status(:not_found)
          |> render(:error, message: "Challenge not found")

        {:error, :already_reported} ->
          conn
          |> put_status(:conflict)
          |> render(:error, message: "You have already reported this challenge")

        {:error, :cannot_report_own} ->
          conn
          |> put_status(:forbidden)
          |> render(:error, message: "You cannot report your own challenge")

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(:error, changeset: changeset)
      end
    else
      :error ->
        conn
        |> put_status(:bad_request)
        |> render(:error, message: "Invalid challenge ID")
    end
  end

  defp get_current_user_id(conn) do
    case conn.assigns[:current_user] do
      %{id: user_id} -> user_id
      _ -> nil
    end
  end
end
