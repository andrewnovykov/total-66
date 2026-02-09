defmodule HeadsUpWeb.Api.GoalCommentJSON do
  def index(%{comments: comments}) do
    %{data: Enum.map(comments, &render_comment/1)}
  end

  def show(%{comment: comment}) do
    %{data: render_comment(comment)}
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

  defp render_comment(comment) do
    %{
      id: comment.id,
      content: comment.content,
      post_id: comment.goal_post_id,
      author: if(comment.user, do: render_user(comment.user), else: nil),
      created_at: comment.inserted_at
    }
  end

  defp render_user(user) do
    %{
      id: user.id,
      name: user.name,
      username: user.user_name,
      image_path: user.image_path
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
