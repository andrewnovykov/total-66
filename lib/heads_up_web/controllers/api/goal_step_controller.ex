defmodule HeadsUpWeb.Api.GoalStepController do
  use HeadsUpWeb, :controller

  alias HeadsUp.Goals

  action_fallback HeadsUpWeb.FallbackController

  # GET /api/goals/:goal_id/steps
  def index(conn, %{"goal_id" => goal_id}) do
    case Integer.parse(goal_id) do
      {id, _} ->
        case Goals.get_goal(id) do
          nil ->
            conn |> put_status(:not_found) |> render(:error, message: "Goal not found")

          goal ->
            steps = Goals.list_goal_steps(goal.id)
            conn |> put_status(:ok) |> render(:index, steps: steps)
        end

      :error ->
        conn |> put_status(:bad_request) |> render(:error, message: "Invalid goal ID")
    end
  end

  # POST /api/goals/:goal_id/steps
  def create(conn, %{"goal_id" => goal_id, "step" => step_params}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(goal_id) do
        {id, _} ->
          case Goals.get_goal(id) do
            nil ->
              conn |> put_status(:not_found) |> render(:error, message: "Goal not found")

            goal ->
              step_params =
                Map.merge(step_params, %{
                  "goal_id" => goal.id,
                  "order" => step_params["order"] || Goals.get_next_step_order(goal.id)
                })

              case Goals.create_goal_step_with_ownership(
                     %{goal: goal, step_params: step_params},
                     current_user_id
                   ) do
                {:ok, step} ->
                  conn |> put_status(:created) |> render(:show, step: step)

                {:error, :unauthorized} ->
                  conn
                  |> put_status(:forbidden)
                  |> render(:error, message: "You can only add steps to your own goals")

                {:error, :step_limit_reached} ->
                  conn
                  |> put_status(:unprocessable_entity)
                  |> render(:error, message: "Maximum 20 steps per goal")

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

  # PUT /api/goals/:goal_id/steps/:id
  def update(conn, %{"goal_id" => goal_id, "id" => id, "step" => step_params}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      with {gid, _} <- Integer.parse(goal_id),
           {sid, _} <- Integer.parse(id) do
        case Goals.get_goal(gid) do
          nil ->
            conn |> put_status(:not_found) |> render(:error, message: "Goal not found")

          _goal ->
            step = Goals.get_goal_step!(sid)

            case Goals.update_goal_step_with_ownership(step, step_params, current_user_id) do
              {:ok, updated_step} ->
                conn |> put_status(:ok) |> render(:show, step: updated_step)

              {:error, :unauthorized} ->
                conn
                |> put_status(:forbidden)
                |> render(:error, message: "You can only update steps on your own goals")

              {:error, changeset} ->
                conn
                |> put_status(:unprocessable_entity)
                |> render(:changeset_error, changeset: changeset)
            end
        end
      else
        :error -> conn |> put_status(:bad_request) |> render(:error, message: "Invalid ID")
      end
    else
      conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
    end
  end

  # DELETE /api/goals/:goal_id/steps/:id
  def delete(conn, %{"goal_id" => _goal_id, "id" => id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {sid, _} ->
          step = Goals.get_goal_step!(sid)

          case Goals.delete_goal_step_with_ownership(step, current_user_id) do
            {:ok, _} ->
              conn
              |> put_status(:ok)
              |> render(:action_success, message: "Step deleted successfully")

            {:error, :unauthorized} ->
              conn
              |> put_status(:forbidden)
              |> render(:error, message: "You can only delete steps on your own goals")

            {:error, _} ->
              conn
              |> put_status(:unprocessable_entity)
              |> render(:error, message: "Failed to delete step")
          end

        :error ->
          conn |> put_status(:bad_request) |> render(:error, message: "Invalid step ID")
      end
    else
      conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
    end
  end

  # POST /api/goals/:goal_id/steps/:id/toggle
  def toggle(conn, %{"goal_id" => _goal_id, "id" => id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {sid, _} ->
          step = Goals.get_goal_step!(sid)

          case Goals.toggle_goal_step_completion_with_ownership(step, current_user_id) do
            {:ok, updated_step} ->
              conn |> put_status(:ok) |> render(:show, step: updated_step)

            {:error, :unauthorized} ->
              conn
              |> put_status(:forbidden)
              |> render(:error, message: "You can only toggle steps on your own goals")

            {:error, _} ->
              conn
              |> put_status(:unprocessable_entity)
              |> render(:error, message: "Failed to toggle step")
          end

        :error ->
          conn |> put_status(:bad_request) |> render(:error, message: "Invalid step ID")
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
end
