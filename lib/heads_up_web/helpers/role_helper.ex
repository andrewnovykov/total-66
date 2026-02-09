defmodule HeadsUpWeb.Helpers.RoleHelper do
  @moduledoc """
  Centralized helper functions for role-based access control.

  Provides consistent role checking across controllers, LiveViews, and templates.
  All role checks should use these helpers to ensure maintainability and
  avoid hardcoded role lists throughout the codebase.

  ## Role Hierarchy
  - `admin` - Full system access, can access all routes
  - `coach` - Coach-specific features, can access coach routes
  - `user` - Standard user access

  ## Usage

  In controllers/LiveViews:
      import HeadsUpWeb.Helpers.RoleHelper
      if is_admin?(user), do: ...

  In templates (via HeadsUpWeb.Helpers.RoleHelper):
      <%= if HeadsUpWeb.Helpers.RoleHelper.is_coach_or_admin?(@current_user) do %>
  """

  @admin_role "admin"
  @coach_role "coach"
  @user_role "user"

  @doc """
  Returns the list of valid roles in the system.
  """
  def valid_roles, do: [@user_role, @coach_role, @admin_role]

  @doc """
  Checks if the user has the admin role.

  Returns `false` if user is nil.

  ## Examples

      iex> is_admin?(%{role: "admin"})
      true

      iex> is_admin?(%{role: "user"})
      false

      iex> is_admin?(nil)
      false
  """
  def is_admin?(nil), do: false
  def is_admin?(%{role: role}), do: role == @admin_role

  @doc """
  Checks if the user has the coach role.

  Returns `false` if user is nil.
  Note: This checks for coach role specifically, not admin.
  Use `is_coach_or_admin?/1` to check if user can access coach features.

  ## Examples

      iex> is_coach?(%{role: "coach"})
      true

      iex> is_coach?(%{role: "admin"})
      false

      iex> is_coach?(nil)
      false
  """
  def is_coach?(nil), do: false
  def is_coach?(%{role: role}), do: role == @coach_role

  @doc """
  Checks if the user has either coach or admin role.

  This is the primary check for coach-level access, since admins
  should also be able to access coach features.

  Returns `false` if user is nil.

  ## Examples

      iex> is_coach_or_admin?(%{role: "coach"})
      true

      iex> is_coach_or_admin?(%{role: "admin"})
      true

      iex> is_coach_or_admin?(%{role: "user"})
      false

      iex> is_coach_or_admin?(nil)
      false
  """
  def is_coach_or_admin?(nil), do: false
  def is_coach_or_admin?(%{role: role}), do: role in [@coach_role, @admin_role]

  @doc """
  Checks if the user has the standard user role.

  Returns `false` if user is nil.

  ## Examples

      iex> is_user?(%{role: "user"})
      true

      iex> is_user?(%{role: "admin"})
      false

      iex> is_user?(nil)
      false
  """
  def is_user?(nil), do: false
  def is_user?(%{role: role}), do: role == @user_role

  @doc """
  Checks if the user has at least the specified role level.

  Role hierarchy: user < coach < admin

  ## Examples

      iex> has_role_at_least?(%{role: "admin"}, "user")
      true

      iex> has_role_at_least?(%{role: "coach"}, "admin")
      false
  """
  def has_role_at_least?(nil, _required_role), do: false

  def has_role_at_least?(%{role: role}, required_role) do
    role_level(role) >= role_level(required_role)
  end

  defp role_level(@user_role), do: 1
  defp role_level(@coach_role), do: 2
  defp role_level(@admin_role), do: 3
  defp role_level(_), do: 0
end
