defmodule HeadsUpWeb.Api.AuthJSON do
  alias HeadsUp.Users

  def registration(%{user: user, token: token}) do
    %{
      success: true,
      message: "Registration successful",
      data: render_user(user),
      token: token
    }
  end

  def session(%{user: user, token: token, message: message}) do
    %{
      success: true,
      message: message,
      data: render_user(user),
      token: token
    }
  end

  def user(%{user: user}) do
    %{
      success: true,
      data: render_user(user)
    }
  end

  def action_success(%{message: message}) do
    %{
      success: true,
      message: message
    }
  end

  def error(%{message: message}) do
    %{
      success: false,
      error: %{
        message: message
      }
    }
  end

  def changeset_error(%{changeset: changeset}) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
          opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
        end)
      end)

    %{
      success: false,
      error: %{
        message: "Validation failed",
        details: errors
      }
    }
  end

  defp render_user(%Users{} = user) do
    %{
      id: user.id,
      email: user.email,
      username: user.user_name,
      name: user.name,
      bio: user.bio,
      image_path: user.image_path,
      role: user.role,
      privacy: user.privacy,
      level: user.level,
      xp: user.xp,
      subscription_type: user.subscription_type
    }
  end
end
