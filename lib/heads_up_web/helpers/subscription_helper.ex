defmodule HeadsUpWeb.Helpers.SubscriptionHelper do
  @moduledoc """
  Helper functions for subscription-based features
  """

  @doc """
  Gets the goal limit for a user based on their subscription type
  """
  def get_goal_limit(user) do
    case user.subscription_type do
      "free" -> 1
      "pro_3" -> 3
      "pro_5" -> 5
      "unlimited" -> :unlimited
      # Default to free tier
      _ -> 1
    end
  end

  @doc """
  Checks if a user can create more goals
  """
  def can_create_goal?(user, current_goal_count) do
    limit = get_goal_limit(user)

    case limit do
      :unlimited -> true
      limit when is_integer(limit) -> current_goal_count < limit
    end
  end

  @doc """
  Gets the subscription display name
  """
  def get_subscription_display_name(subscription_type) do
    case subscription_type do
      "free" -> "Free (1 goal)"
      "pro_3" -> "Pro (3 goals)"
      "pro_5" -> "Pro+ (5 goals)"
      "unlimited" -> "Premium (Unlimited goals)"
      _ -> "Free (1 goal)"
    end
  end
end
