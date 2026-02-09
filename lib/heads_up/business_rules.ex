defmodule HeadsUp.BusinessRules do
  @moduledoc """
  Centralized business rules for HeadsUp platform.
  Enforces global constraints like active item limits and interaction permissions.

  Active item limits by role/subscription:
  - Admin: unlimited
  - Free users: 3
  - Pro users: 10
  """

  import Ecto.Query, warn: false
  alias HeadsUp.Repo

  @free_limit 3
  @pro_limit 10

  @doc """
  Returns the maximum number of active items for a given user.
  Admins have no limit (returns :unlimited).
  """
  def max_active_items(user_id) do
    user = Repo.get!(HeadsUp.Users, user_id)

    cond do
      user.role == "admin" -> :unlimited
      user.subscription_type in ["pro_3", "pro_5", "unlimited"] -> @pro_limit
      true -> @free_limit
    end
  end

  @doc """
  Counts total active items for a user (goals + challenges).
  Active items include:
  - Goals with status :active
  - Personal challenges (non-template) with status :active
  """
  def count_active_items(user_id) do
    active_goals = count_active_goals(user_id)
    active_challenges = count_active_challenges(user_id)
    active_goals + active_challenges
  end

  @doc """
  Checks if a user can create/start a new active item.
  Returns :ok or {:error, :active_limit_reached}.
  Admins always return :ok (unlimited).
  """
  def can_create_active_item?(user_id) do
    limit = max_active_items(user_id)

    case limit do
      :unlimited ->
        :ok

      n when is_integer(n) ->
        if count_active_items(user_id) < n do
          :ok
        else
          {:error, :active_limit_reached}
        end
    end
  end

  @doc """
  Checks if a user is a guest (nil user_id).
  Returns :ok or {:error, :guest_not_allowed}.
  """
  def require_authenticated(nil), do: {:error, :guest_not_allowed}
  def require_authenticated(_user_id), do: :ok

  defp count_active_goals(user_id) do
    from(g in HeadsUp.Goal,
      where: g.user_id == ^user_id and g.status == :active and is_nil(g.deleted_at)
    )
    |> Repo.aggregate(:count)
  end

  defp count_active_challenges(user_id) do
    from(c in HeadsUp.Challenges.Challenge,
      where: c.creator_user_id == ^user_id and c.is_template == false and c.status == :active
    )
    |> Repo.aggregate(:count)
  end
end
