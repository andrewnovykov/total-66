defmodule HeadsUpWeb.Helpers.AvatarHelper do
  @moduledoc """
  Helper functions for user avatars
  """

  @doc """
  Gets the appropriate avatar URL for a user, with fallback to default avatar
  """
  def get_user_avatar(user) do
    case user.image_path do
      nil ->
        get_default_avatar(user.name || user.user_name || "User")

      "" ->
        get_default_avatar(user.name || user.user_name || "User")

      path when is_binary(path) ->
        path

      _ ->
        get_default_avatar(user.name || user.user_name || "User")
    end
  end

  @doc """
  Generates a default avatar URL using ui-avatars.com service
  """
  def get_default_avatar(name \\ "User") do
    # Using a generic avatar service that generates initials from name
    # The service automatically handles URL encoding for names with spaces
    "https://ui-avatars.com/api/?name=#{URI.encode(name)}&background=6366f1&color=ffffff&size=128&bold=true"
  end
end
