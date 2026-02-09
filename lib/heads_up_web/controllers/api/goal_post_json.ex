defmodule HeadsUpWeb.Api.GoalPostJSON do
  def index(%{posts: posts, current_user_id: current_user_id}) do
    %{data: Enum.map(posts, &render_post(&1, current_user_id))}
  end

  def show(%{post: post, current_user_id: current_user_id}) do
    %{data: render_post(post, current_user_id)}
  end

  def action_success(%{message: message}) do
    %{success: true, message: message}
  end

  def error(%{message: message}) do
    %{success: false, error: %{message: message}}
  end

  def changeset_error(%{changeset: changeset}) do
    %{
      success: false,
      error: %{
        message: "Validation failed",
        details: translate_errors(changeset)
      }
    }
  end

  defp render_post(post, current_user_id) do
    %{
      id: post.id,
      content: post.content,
      post_type: post.post_type,
      image_path: post.image_path,
      goal_id: post.goal_id,
      step_id: post.step_id,
      like_count: Map.get(post, :like_count, 0),
      is_liked: Map.get(post, :user_liked, false),
      is_owner: post.user_id == current_user_id,
      author: if(post.user, do: render_user(post.user), else: nil),
      created_at: post.inserted_at,
      updated_at: post.updated_at
    }
  end

  defp render_user(user) do
    %{
      id: user.id,
      name: user.name,
      username: user.user_name,
      image_path: user.image_path,
      level: user.level
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
