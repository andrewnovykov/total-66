defmodule HeadsUpWeb.Api.ActivityJSON do
  alias HeadsUp.{UserActivity, Users}

  def activities(%{activities: activities}) do
    %{
      data: Enum.map(activities, &render_activity/1),
      success: true
    }
  end

  def feed(%{feed_items: feed_items}) do
    %{
      data: Enum.map(feed_items, &render_feed_item/1),
      success: true
    }
  end

  def chart(%{chart_data: chart_data}) do
    %{
      data: chart_data,
      success: true
    }
  end

  def stats(%{stats: stats}) do
    %{
      data: stats,
      success: true
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

  defp render_activity(%UserActivity{} = activity) do
    %{
      id: activity.id,
      activity_type: activity.activity_type,
      xp_change: activity.xp_change,
      description: activity.description,
      metadata: activity.metadata,
      created_at: activity.inserted_at,
      user: render_user(activity.user)
    }
  end

  defp render_feed_item(item) do
    %{
      id: item.id,
      activity_type: item.activity_type,
      xp_change: item.xp_change,
      description: item.user_friendly_description,
      created_at: item.inserted_at,
      user: render_user(item.user)
    }
  end

  defp render_user(%Users{} = user) do
    %{
      id: user.id,
      name: user.name,
      username: user.user_name,
      image_path: user.image_path,
      level: user.level,
      bio: user.bio
    }
  end
end
