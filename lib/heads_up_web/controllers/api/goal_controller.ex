defmodule HeadsUpWeb.Api.GoalController do
  use HeadsUpWeb, :controller

  import Ecto.Query
  alias HeadsUp.{Goals, Groups, Repo}
  alias HeadsUp.Goal

  action_fallback HeadsUpWeb.FallbackController

  # GET /api/goals - Get all public goals
  def index(conn, params) do
    current_user_id = get_current_user_id(conn)

    goals =
      Goals.list_goals()
      |> Enum.filter(&(&1.privacy == :public))
      |> Repo.preload([
        :group,
        :user,
        :goal_likes,
        :goal_subscriptions,
        :goal_steps,
        goal_posts:
          from(p in HeadsUp.Goals.GoalPost, order_by: [desc: p.inserted_at], preload: [:user])
      ])
      |> Goals.add_social_counts()
      |> apply_filters(params)
      |> paginate(params)

    conn
    |> put_status(:ok)
    |> render(:index, goals: goals, current_user_id: current_user_id)
  end

  # GET /api/goals/my - Get current user's goals
  def my_goals(conn, params) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      goals =
        Goals.list_goals_by_user(current_user_id)
        |> Repo.preload([
          :group,
          :user,
          :goal_likes,
          :goal_subscriptions,
          :goal_steps,
          goal_posts:
            from(p in HeadsUp.Goals.GoalPost, order_by: [desc: p.inserted_at], preload: [:user])
        ])
        |> Goals.add_social_counts()
        |> paginate(params)

      conn
      |> put_status(:ok)
      |> render(:index, goals: goals, current_user_id: current_user_id)
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "Authentication required")
    end
  end

  # GET /api/goals/category/:category_id - Get goals by category
  def by_category(conn, %{"category_id" => category_id} = params) do
    current_user_id = get_current_user_id(conn)

    case Integer.parse(category_id) do
      {category_id, _} ->
        # Verify category exists
        try do
          _group = Groups.get_group!(category_id)
          goals = Goals.list_public_goals_by_group(category_id)
          # Need to add missing preloads for API
          goals = Repo.preload(goals, [:goal_steps, goal_posts: [:user]])

          goals =
            goals
            |> apply_filters(params)
            |> paginate(params)

          conn
          |> put_status(:ok)
          |> render(:index, goals: goals, current_user_id: current_user_id)
        rescue
          Ecto.NoResultsError ->
            conn
            |> put_status(:not_found)
            |> render(:error, message: "Category not found")
        end

      :error ->
        conn
        |> put_status(:bad_request)
        |> render(:error, message: "Invalid category ID")
    end
  end

  # GET /api/goals/:id - Get specific goal by ID
  def show(conn, %{"id" => id}) do
    current_user_id = get_current_user_id(conn)

    case Integer.parse(id) do
      {goal_id, _} ->
        case Goals.get_goal(goal_id) do
          nil ->
            conn
            |> put_status(:not_found)
            |> render(:error, message: "Goal not found")

          goal ->
            # Check if goal is deleted (soft deleted goals should not be accessible)
            if goal.deleted_at do
              conn
              |> put_status(:not_found)
              |> render(:error, message: "Goal not found")
            else
              # Load goal posts separately with explicit ordering
              goal_posts =
                from(p in HeadsUp.Goals.GoalPost,
                  where: p.goal_id == ^goal.id,
                  order_by: [desc: p.inserted_at],
                  preload: [:user]
                )
                |> Repo.all()

              goal =
                Repo.preload(goal, [:group, :user, :goal_likes, :goal_subscriptions, :goal_steps])

              goal = Map.put(goal, :goal_posts, goal_posts)

              goal =
                [goal]
                |> Goals.add_social_counts()
                |> List.first()

              # Check if user can view this goal based on privacy
              if can_view_goal?(goal, current_user_id) do
                conn
                |> put_status(:ok)
                |> render(:show, goal: goal, current_user_id: current_user_id)
              else
                conn
                |> put_status(:forbidden)
                |> render(:error, message: "Access denied")
              end
            end
        end

      :error ->
        conn
        |> put_status(:bad_request)
        |> render(:error, message: "Invalid goal ID")
    end
  end

  # POST /api/goals - Create new goal
  def create(conn, %{"goal" => goal_params}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      # Add user_id to params
      goal_params = Map.put(goal_params, "user_id", current_user_id)

      case Goals.create_goal(goal_params) do
        {:ok, goal} ->
          goal =
            Repo.preload(goal, [
              :group,
              :user,
              :goal_likes,
              :goal_subscriptions,
              :goal_steps,
              goal_posts: [:user]
            ])

          goal =
            [goal]
            |> Goals.add_social_counts()
            |> List.first()

          conn
          |> put_status(:created)
          |> render(:show, goal: goal, current_user_id: current_user_id)

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(:changeset_error, changeset: changeset)
      end
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "Authentication required")
    end
  end

  # PUT /api/goals/:id - Update goal
  def update(conn, %{"id" => id, "goal" => goal_params}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {goal_id, _} ->
          case Goals.get_goal(goal_id) do
            nil ->
              conn
              |> put_status(:not_found)
              |> render(:error, message: "Goal not found")

            goal ->
              # Check if goal is deleted or failed (failed goals can only be deleted)
              cond do
                goal.deleted_at ->
                  conn
                  |> put_status(:not_found)
                  |> render(:error, message: "Goal not found")

                goal.status == :failed ->
                  conn
                  |> put_status(:forbidden)
                  |> render(:error, message: "Failed goals can only be deleted")

                true ->
                  case Goals.update_goal_with_ownership(goal, goal_params, current_user_id) do
                    {:ok, updated_goal} ->
                      updated_goal =
                        Repo.preload(updated_goal, [
                          :group,
                          :user,
                          :goal_likes,
                          :goal_subscriptions,
                          :goal_steps,
                          goal_posts: [:user]
                        ])

                      updated_goal =
                        [updated_goal]
                        |> Goals.add_social_counts()
                        |> List.first()

                      conn
                      |> put_status(:ok)
                      |> render(:show, goal: updated_goal, current_user_id: current_user_id)

                    {:error, :unauthorized} ->
                      conn
                      |> put_status(:forbidden)
                      |> render(:error, message: "You can only update your own goals")

                    {:error, :frozen} ->
                      conn
                      |> put_status(:forbidden)
                      |> render(:error,
                        message: "Frozen goals cannot be updated. Unfreeze the goal first."
                      )

                    {:error, :failed} ->
                      conn
                      |> put_status(:forbidden)
                      |> render(:error, message: "Failed goals can only be deleted")

                    {:error, changeset} ->
                      conn
                      |> put_status(:unprocessable_entity)
                      |> render(:changeset_error, changeset: changeset)
                  end
              end
          end

        :error ->
          conn
          |> put_status(:bad_request)
          |> render(:error, message: "Invalid goal ID")
      end
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "Authentication required")
    end
  end

  # DELETE /api/goals/:id - Delete goal
  def delete(conn, %{"id" => id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {goal_id, _} ->
          case Goals.get_goal(goal_id) do
            nil ->
              conn
              |> put_status(:not_found)
              |> render(:error, message: "Goal not found")

            goal ->
              case Goals.soft_delete_goal_with_ownership(goal, current_user_id) do
                {:ok, _deleted_goal} ->
                  conn
                  |> put_status(:ok)
                  |> render(:delete, message: "Goal deleted successfully")

                {:error, :unauthorized} ->
                  conn
                  |> put_status(:forbidden)
                  |> render(:error, message: "You can only delete your own goals")

                {:error, _changeset} ->
                  conn
                  |> put_status(:unprocessable_entity)
                  |> render(:error, message: "Failed to delete goal")
              end
          end

        :error ->
          conn
          |> put_status(:bad_request)
          |> render(:error, message: "Invalid goal ID")
      end
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "Authentication required")
    end
  end

  # POST /api/goals/:id/restore - Restore a deleted goal
  def restore(conn, %{"id" => id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {goal_id, _} ->
          case Goals.get_goal(goal_id) do
            nil ->
              conn
              |> put_status(:not_found)
              |> render(:error, message: "Goal not found")

            goal ->
              # Failed goals cannot be restored, only deleted
              if goal.status == :failed do
                conn
                |> put_status(:forbidden)
                |> render(:error, message: "Failed goals can only be deleted")
              else
                case Goals.restore_goal_with_ownership(goal, current_user_id) do
                  {:ok, restored_goal} ->
                    restored_goal =
                      Repo.preload(restored_goal, [
                        :group,
                        :user,
                        :goal_likes,
                        :goal_subscriptions,
                        :goal_steps,
                        goal_posts: [:user]
                      ])

                    restored_goal =
                      [restored_goal]
                      |> Goals.add_social_counts()
                      |> List.first()

                    conn
                    |> put_status(:ok)
                    |> render(:show, goal: restored_goal, current_user_id: current_user_id)

                  {:error, :unauthorized} ->
                    conn
                    |> put_status(:forbidden)
                    |> render(:error, message: "You can only restore your own goals")

                  {:error, _changeset} ->
                    conn
                    |> put_status(:unprocessable_entity)
                    |> render(:error, message: "Failed to restore goal")
                end
              end
          end

        :error ->
          conn
          |> put_status(:bad_request)
          |> render(:error, message: "Invalid goal ID")
      end
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "Authentication required")
    end
  end

  # POST /api/goals/:id/fail - Mark goal as failed with reason
  def fail(conn, %{"id" => id, "reason" => reason}) when is_binary(reason) and reason != "" do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {goal_id, _} ->
          case Goals.get_goal(goal_id) do
            nil ->
              conn
              |> put_status(:not_found)
              |> render(:error, message: "Goal not found")

            goal ->
              # Check if goal is deleted
              if goal.deleted_at do
                conn
                |> put_status(:not_found)
                |> render(:error, message: "Goal not found")
              else
                case Goals.fail_goal_with_ownership(goal, reason, current_user_id) do
                  {:ok, failed_goal} ->
                    failed_goal =
                      Repo.preload(failed_goal, [
                        :group,
                        :user,
                        :goal_likes,
                        :goal_subscriptions,
                        :goal_steps,
                        goal_posts: [:user]
                      ])

                    failed_goal =
                      [failed_goal]
                      |> Goals.add_social_counts()
                      |> List.first()

                    conn
                    |> put_status(:ok)
                    |> render(:show, goal: failed_goal, current_user_id: current_user_id)

                  {:error, :unauthorized} ->
                    conn
                    |> put_status(:forbidden)
                    |> render(:error, message: "You can only fail your own goals")

                  {:error, _changeset} ->
                    conn
                    |> put_status(:unprocessable_entity)
                    |> render(:error, message: "Failed to mark goal as failed")
                end
              end
          end

        :error ->
          conn
          |> put_status(:bad_request)
          |> render(:error, message: "Invalid goal ID")
      end
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "Authentication required")
    end
  end

  def fail(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> render(:error, message: "Failure reason is required")
  end

  # GET /api/goals/deleted - Get user's deleted goals
  def deleted_goals(conn, params) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      goals =
        Goals.list_deleted_goals_by_user(current_user_id)
        |> Repo.preload([
          :group,
          :user,
          :goal_likes,
          :goal_subscriptions,
          :goal_steps,
          goal_posts:
            from(p in HeadsUp.Goals.GoalPost, order_by: [desc: p.inserted_at], preload: [:user])
        ])
        |> Goals.add_social_counts()
        |> paginate(params)

      conn
      |> put_status(:ok)
      |> render(:index, goals: goals, current_user_id: current_user_id)
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "Authentication required")
    end
  end

  # POST /api/goals/:id/freeze - Freeze a goal
  def freeze(conn, %{"id" => id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {goal_id, _} ->
          case Goals.get_goal(goal_id) do
            nil ->
              conn
              |> put_status(:not_found)
              |> render(:error, message: "Goal not found")

            goal ->
              # Check if goal is deleted
              if goal.deleted_at do
                conn
                |> put_status(:not_found)
                |> render(:error, message: "Goal not found")
              else
                case Goals.freeze_goal_with_ownership(goal, current_user_id) do
                  {:ok, frozen_goal} ->
                    frozen_goal =
                      Repo.preload(frozen_goal, [
                        :group,
                        :user,
                        :goal_likes,
                        :goal_subscriptions,
                        :goal_steps,
                        goal_posts: [:user]
                      ])

                    frozen_goal =
                      [frozen_goal]
                      |> Goals.add_social_counts()
                      |> List.first()

                    conn
                    |> put_status(:ok)
                    |> render(:show, goal: frozen_goal, current_user_id: current_user_id)

                  {:error, :unauthorized} ->
                    conn
                    |> put_status(:forbidden)
                    |> render(:error, message: "You can only freeze your own goals")

                  {:error, :failed} ->
                    conn
                    |> put_status(:forbidden)
                    |> render(:error, message: "Failed goals cannot be frozen")

                  {:error, _changeset} ->
                    conn
                    |> put_status(:unprocessable_entity)
                    |> render(:error, message: "Failed to freeze goal")
                end
              end
          end

        :error ->
          conn
          |> put_status(:bad_request)
          |> render(:error, message: "Invalid goal ID")
      end
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "Authentication required")
    end
  end

  # POST /api/goals/:id/unfreeze - Unfreeze a goal
  def unfreeze(conn, %{"id" => id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {goal_id, _} ->
          case Goals.get_goal(goal_id) do
            nil ->
              conn
              |> put_status(:not_found)
              |> render(:error, message: "Goal not found")

            goal ->
              # Check if goal is deleted
              if goal.deleted_at do
                conn
                |> put_status(:not_found)
                |> render(:error, message: "Goal not found")
              else
                case Goals.unfreeze_goal_with_ownership(goal, current_user_id) do
                  {:ok, unfrozen_goal} ->
                    unfrozen_goal =
                      Repo.preload(unfrozen_goal, [
                        :group,
                        :user,
                        :goal_likes,
                        :goal_subscriptions,
                        :goal_steps,
                        goal_posts: [:user]
                      ])

                    unfrozen_goal =
                      [unfrozen_goal]
                      |> Goals.add_social_counts()
                      |> List.first()

                    conn
                    |> put_status(:ok)
                    |> render(:show, goal: unfrozen_goal, current_user_id: current_user_id)

                  {:error, :unauthorized} ->
                    conn
                    |> put_status(:forbidden)
                    |> render(:error, message: "You can only unfreeze your own goals")

                  {:error, _changeset} ->
                    conn
                    |> put_status(:unprocessable_entity)
                    |> render(:error, message: "Failed to unfreeze goal")
                end
              end
          end

        :error ->
          conn
          |> put_status(:bad_request)
          |> render(:error, message: "Invalid goal ID")
      end
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "Authentication required")
    end
  end

  # POST /api/goals/:id/like - Like a goal
  def like(conn, %{"id" => id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {goal_id, _} ->
          case Goals.like_goal(goal_id, current_user_id) do
            {:ok, _} ->
              conn
              |> put_status(:ok)
              |> render(:action_success, message: "Goal liked successfully")

            {:error, :cannot_like_own_goal} ->
              conn
              |> put_status(:forbidden)
              |> render(:error, message: "You cannot like your own goal")

            {:error, _} ->
              conn
              |> put_status(:unprocessable_entity)
              |> render(:error, message: "Failed to like goal")
          end

        :error ->
          conn
          |> put_status(:bad_request)
          |> render(:error, message: "Invalid goal ID")
      end
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "Authentication required")
    end
  end

  # DELETE /api/goals/:id/like - Unlike a goal
  def unlike(conn, %{"id" => id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {goal_id, _} ->
          case Goals.unlike_goal(goal_id, current_user_id) do
            {:ok, _} ->
              conn
              |> put_status(:ok)
              |> render(:action_success, message: "Goal unliked successfully")

            {:error, _} ->
              conn
              |> put_status(:unprocessable_entity)
              |> render(:error, message: "Failed to unlike goal")
          end

        :error ->
          conn
          |> put_status(:bad_request)
          |> render(:error, message: "Invalid goal ID")
      end
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "Authentication required")
    end
  end

  # POST /api/goals/:id/subscribe - Subscribe to a goal
  def subscribe(conn, %{"id" => id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {goal_id, _} ->
          case Goals.subscribe_to_goal(goal_id, current_user_id) do
            {:ok, _} ->
              conn
              |> put_status(:ok)
              |> render(:action_success, message: "Subscribed to goal successfully")

            {:error, :cannot_subscribe_to_own_goal} ->
              conn
              |> put_status(:forbidden)
              |> render(:error, message: "You cannot subscribe to your own goal")

            {:error, :access_denied} ->
              conn
              |> put_status(:forbidden)
              |> render(:error, message: "Access denied")

            {:error, :must_be_friends} ->
              conn
              |> put_status(:forbidden)
              |> render(:error,
                message: "You must be friends with the owner to subscribe to this goal"
              )

            {:error, _} ->
              conn
              |> put_status(:unprocessable_entity)
              |> render(:error, message: "Failed to subscribe to goal")
          end

        :error ->
          conn
          |> put_status(:bad_request)
          |> render(:error, message: "Invalid goal ID")
      end
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "Authentication required")
    end
  end

  # DELETE /api/goals/:id/subscribe - Unsubscribe from a goal
  def unsubscribe(conn, %{"id" => id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {goal_id, _} ->
          case Goals.unsubscribe_from_goal(goal_id, current_user_id) do
            {:ok, _} ->
              conn
              |> put_status(:ok)
              |> render(:action_success, message: "Unsubscribed from goal successfully")

            {:error, _} ->
              conn
              |> put_status(:unprocessable_entity)
              |> render(:error, message: "Failed to unsubscribe from goal")
          end

        :error ->
          conn
          |> put_status(:bad_request)
          |> render(:error, message: "Invalid goal ID")
      end
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "Authentication required")
    end
  end

  # Private helper functions

  defp get_current_user_id(conn) do
    # Extract user ID from JWT token or session
    # For now, we'll use a simple approach - check if there's a user in assigns
    case conn.assigns[:current_user] do
      %{id: user_id} -> user_id
      _ -> nil
    end
  end

  defp can_view_goal?(goal, current_user_id) do
    case goal.privacy do
      :public ->
        true

      :private ->
        current_user_id && current_user_id == goal.user_id

      :friends ->
        current_user_id &&
          (current_user_id == goal.user_id || are_friends?(current_user_id, goal.user_id))

      _ ->
        false
    end
  end

  defp are_friends?(user1_id, user2_id) do
    HeadsUp.Accounts.are_friends?(user1_id, user2_id)
  end

  defp apply_filters(goals, params) do
    goals
    |> filter_by_status(params["status"])
    |> filter_by_search(params["search"])
    |> sort_goals(params["sort"])
  end

  defp filter_by_status(goals, nil), do: goals

  defp filter_by_status(goals, status)
       when status in ["active", "completed", "paused", "cancelled"] do
    status_atom = String.to_atom(status)
    Enum.filter(goals, &(&1.status == status_atom))
  end

  defp filter_by_status(goals, _), do: goals

  defp filter_by_search(goals, nil), do: goals
  defp filter_by_search(goals, ""), do: goals

  defp filter_by_search(goals, search_term) do
    search_term = String.downcase(search_term)

    Enum.filter(goals, fn goal ->
      title_match = String.contains?(String.downcase(goal.title), search_term)

      desc_match =
        goal.description && String.contains?(String.downcase(goal.description), search_term)

      category_match =
        goal.group && String.contains?(String.downcase(goal.group.name), search_term)

      user_match = goal.user && String.contains?(String.downcase(goal.user.name), search_term)

      title_match || desc_match || category_match || user_match
    end)
  end

  defp sort_goals(goals, "created_desc"),
    do: Enum.sort_by(goals, & &1.inserted_at, {:desc, DateTime})

  defp sort_goals(goals, "created_asc"),
    do: Enum.sort_by(goals, & &1.inserted_at, {:asc, DateTime})

  defp sort_goals(goals, "updated_desc"),
    do: Enum.sort_by(goals, & &1.updated_at, {:desc, DateTime})

  defp sort_goals(goals, "updated_asc"),
    do: Enum.sort_by(goals, & &1.updated_at, {:asc, DateTime})

  defp sort_goals(goals, "progress_desc"), do: Enum.sort_by(goals, & &1.progress, :desc)
  defp sort_goals(goals, "progress_asc"), do: Enum.sort_by(goals, & &1.progress, :asc)
  defp sort_goals(goals, "title_asc"), do: Enum.sort_by(goals, &String.downcase(&1.title), :asc)
  defp sort_goals(goals, "title_desc"), do: Enum.sort_by(goals, &String.downcase(&1.title), :desc)
  defp sort_goals(goals, _), do: goals

  defp paginate(goals, params) do
    page =
      case params["page"] do
        nil ->
          1

        page_str ->
          case Integer.parse(page_str) do
            {page, _} when page > 0 -> page
            _ -> 1
          end
      end

    per_page =
      case params["per_page"] do
        nil ->
          20

        per_page_str ->
          case Integer.parse(per_page_str) do
            {per_page, _} when per_page > 0 and per_page <= 100 -> per_page
            _ -> 20
          end
      end

    offset = (page - 1) * per_page

    goals
    |> Enum.drop(offset)
    |> Enum.take(per_page)
  end
end
