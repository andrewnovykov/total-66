defmodule HeadsUpWeb.Api.UserJSON do
  alias HeadsUp.{Users, Friendship}

  def index(%{users: users}) do
    %{
      data: Enum.map(users, &render_user/1),
      meta: %{count: length(users)}
    }
  end

  def show(%{user: user, stats: stats, current_user_id: current_user_id}) do
    %{data: render_user_detailed(user, stats, current_user_id)}
  end

  def users_list(%{users: users}) do
    %{data: Enum.map(users, &render_user/1)}
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

  def friend_requests(%{requests: requests}) do
    %{data: Enum.map(requests, &render_friend_request/1)}
  end

  def friends(%{friends: friends}) do
    %{data: Enum.map(friends, &render_user/1)}
  end

  defp render_friend_request(%Friendship{} = request) do
    %{
      id: request.id,
      from: render_user(request.user),
      status: request.status,
      sent_at: request.inserted_at
    }
  end

  defp render_user(%Users{} = user) do
    %{
      id: user.id,
      username: user.user_name,
      name: user.name,
      bio: user.bio,
      image_path: user.image_path,
      level: user.level,
      role: user.role,
      privacy: user.privacy || "public"
    }
  end

  defp render_user_detailed(%Users{} = user, stats, current_user_id) do
    base = render_user(user)

    Map.merge(base, %{
      email: if(current_user_id == user.id, do: user.email, else: nil),
      about: user.about,
      xp: user.xp,
      subscription_type: user.subscription_type,
      created_at: user.inserted_at,
      stats: render_stats(stats)
    })
  end

  defp render_stats(nil), do: nil

  defp render_stats(stats) do
    %{
      followers_count: Map.get(stats, :followers_count, 0),
      following_count: Map.get(stats, :following_count, 0),
      friends_count: Map.get(stats, :friends_count, 0),
      goals_count: Map.get(stats, :goals_count, 0)
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
