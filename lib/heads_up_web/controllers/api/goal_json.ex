defmodule HeadsUpWeb.Api.GoalJSON do
  @moduledoc """
  JSON views for Goal API endpoints
  """

  @doc """
  Renders a list of goals.
  """
  def index(%{goals: goals, current_user_id: current_user_id}) do
    %{
      data: for(goal <- goals, do: goal_data(goal, current_user_id)),
      meta: %{
        count: length(goals),
        page_info: %{
          has_next_page: false,
          has_previous_page: false
        }
      }
    }
  end

  @doc """
  Renders a single goal.
  """
  def show(%{goal: goal, current_user_id: current_user_id}) do
    %{data: goal_data(goal, current_user_id)}
  end

  @doc """
  Renders goal created/updated response.
  """
  def create(%{goal: goal, current_user_id: current_user_id}) do
    %{
      data: goal_data(goal, current_user_id),
      message: "Goal created successfully"
    }
  end

  @doc """
  Renders goal deletion response.
  """
  def delete(%{message: message}) do
    %{
      message: message,
      success: true
    }
  end

  @doc """
  Renders action success response (like, subscribe, etc.).
  """
  def action_success(%{message: message}) do
    %{
      message: message,
      success: true
    }
  end

  @doc """
  Renders error response.
  """
  def error(%{message: message}) do
    %{
      error: %{
        message: message
      },
      success: false
    }
  end

  @doc """
  Renders changeset error response.
  """
  def changeset_error(%{changeset: changeset}) do
    %{
      error: %{
        message: "Validation failed",
        details: translate_errors(changeset)
      },
      success: false
    }
  end

  # Private helper functions

  defp goal_data(goal, current_user_id) do
    %{
      id: goal.id,
      title: goal.title,
      description: goal.description,
      big_description: goal.big_description,
      status: goal.status,
      privacy: goal.privacy,
      progress: goal.progress,
      target_date: goal.target_date,
      image_path: goal.image_path,
      failure_reason: goal.failure_reason,
      failed_at: goal.failed_at,
      is_frozen: goal.is_frozen,

      # Timestamps
      created_at: goal.inserted_at,
      updated_at: goal.updated_at,

      # Category/Group information
      category: if(goal.group, do: category_data(goal.group), else: nil),

      # User/Creator information
      creator: if(goal.user, do: user_data(goal.user), else: nil),

      # Social counts
      likes_count: Map.get(goal, :like_count, 0),
      subscribers_count: Map.get(goal, :subscriber_count, 0),

      # User interaction status (if authenticated)
      user_interactions:
        if(current_user_id, do: user_interactions(goal, current_user_id), else: nil),

      # Goal steps
      steps: if(goal.goal_steps, do: Enum.map(goal.goal_steps, &step_data/1), else: []),

      # Recent posts (if loaded)
      recent_posts:
        if(goal.goal_posts, do: Enum.take(goal.goal_posts, 5) |> Enum.map(&post_data/1), else: [])
    }
  end

  defp category_data(group) do
    %{
      id: group.id,
      name: group.name,
      description: group.description,
      image_path: group.image_path
    }
  end

  defp user_data(user) do
    %{
      id: user.id,
      name: user.name,
      username: user.user_name,
      level: user.level,
      image_path: user.image_path,
      bio: user.bio
    }
  end

  defp user_interactions(goal, current_user_id) do
    # Check if user has liked or subscribed to this goal
    is_liked = Enum.any?(goal.goal_likes || [], &(&1.user_id == current_user_id))
    is_subscribed = Enum.any?(goal.goal_subscriptions || [], &(&1.user_id == current_user_id))
    is_owner = goal.user_id == current_user_id

    %{
      is_liked: is_liked,
      is_subscribed: is_subscribed,
      is_owner: is_owner,
      can_edit: is_owner,
      can_delete: is_owner
    }
  end

  defp step_data(step) do
    %{
      id: step.id,
      title: step.title,
      completed: step.completed,
      order: step.order,
      created_at: step.inserted_at,
      updated_at: step.updated_at
    }
  end

  defp post_data(post) do
    %{
      id: post.id,
      content: post.content,
      post_type: post.post_type,
      image_path: post.image_path,
      created_at: post.inserted_at,
      author: if(post.user, do: user_data(post.user), else: nil)
    }
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
