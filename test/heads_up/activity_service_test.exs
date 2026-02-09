defmodule HeadsUp.ActivityServiceTest do
  use HeadsUp.DataCase
  alias HeadsUp.{ActivityService, Users, UserLevel, UserActivity}

  describe "track_activity/3" do
    test "creates activity and updates user XP" do
      user = user_fixture()

      {:ok, activity} = ActivityService.track_activity(user.id, "goal_created")

      assert activity.activity_type == "goal_created"
      assert activity.xp_change == 50

      updated_user = Repo.get!(Users, user.id)
      assert updated_user.xp == 50
      assert updated_user.level == 1
    end

    test "handles level progression" do
      user = user_fixture()

      # Add enough XP to reach level 2 (100 XP needed)
      {:ok, _} = ActivityService.track_activity(user.id, "goal_completed")
      {:ok, _} = ActivityService.track_activity(user.id, "goal_completed")

      updated_user = Repo.get!(Users, user.id)
      assert updated_user.xp == 2000
      # Should be higher than level 1
      assert updated_user.level > 1
    end

    test "handles negative XP correctly" do
      user = user_fixture()

      # First gain some XP
      {:ok, _} = ActivityService.track_activity(user.id, "goal_created")

      # Then lose some (but XP can't go below 0)
      {:ok, _} = ActivityService.track_activity(user.id, "goal_failed")

      updated_user = Repo.get!(Users, user.id)
      # 50 - 200 = -150, but minimum is 0
      assert updated_user.xp == 0
    end

    test "creates user_level record" do
      user = user_fixture()

      {:ok, _} = ActivityService.track_activity(user.id, "goal_created")

      user_level = Repo.get_by!(UserLevel, user_id: user.id)
      assert user_level.level == 1
      assert user_level.xp == 50
      assert user_level.level_name == "Seastar"
    end
  end

  describe "get_user_activity_summary/2" do
    test "returns activity summary for user" do
      user = user_fixture()

      {:ok, _} = ActivityService.track_activity(user.id, "goal_created")
      {:ok, _} = ActivityService.track_activity(user.id, "post_created")

      summary = ActivityService.get_user_activity_summary(user.id, 30)

      # 50 + 25
      assert summary.total_xp == 75
      assert summary.activity_count == 2
      assert length(summary.activities) == 2
    end
  end

  defp user_fixture(attrs \\ %{}) do
    random_id = System.unique_integer([:positive])

    attrs =
      Enum.into(attrs, %{
        name: "Test User",
        user_name: "test#{random_id}",
        email: "test#{random_id}@example.com",
        password: "password123456"
      })

    {:ok, user} = HeadsUp.Auth.register_user(attrs)
    user
  end
end
