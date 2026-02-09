defmodule HeadsUp.ActivityServiceTest do
  use HeadsUp.DataCase
  alias HeadsUp.{ActivityService, Users, UserLevel, UserActivity}

  describe "track_activity/3" do
    test "creates activity and updates user XP" do
      user = user_fixture()

      {:ok, activity} = ActivityService.track_activity(user.id, "post_created")

      assert activity.activity_type == "post_created"
      assert activity.xp_change == 25

      updated_user = Repo.get!(Users, user.id)
      assert updated_user.xp == 25
      assert updated_user.level == 1
    end

    test "handles level progression" do
      user = user_fixture()

      # Add enough XP to reach level 2 by creating many activities
      for _ <- 1..10 do
        {:ok, _} = ActivityService.track_activity(user.id, "post_created")
      end

      updated_user = Repo.get!(Users, user.id)
      # 10 * 25 = 250 XP
      assert updated_user.xp == 250
      # Should be higher than level 1
      assert updated_user.level >= 1
    end

    test "handles zero XP activities correctly" do
      user = user_fixture()

      # First gain some XP
      {:ok, _} = ActivityService.track_activity(user.id, "post_created")

      # Challenge activities give 0 XP by default
      {:ok, _} = ActivityService.track_activity(user.id, "challenge_created")

      updated_user = Repo.get!(Users, user.id)
      assert updated_user.xp == 25
    end

    test "creates user_level record" do
      user = user_fixture()

      {:ok, _} = ActivityService.track_activity(user.id, "post_created")

      user_level = Repo.get_by!(UserLevel, user_id: user.id)
      assert user_level.level == 1
      assert user_level.xp == 25
      assert user_level.level_name == "Seastar"
    end
  end

  describe "get_user_activity_summary/2" do
    test "returns activity summary for user" do
      user = user_fixture()

      {:ok, _} = ActivityService.track_activity(user.id, "challenge_created")
      {:ok, _} = ActivityService.track_activity(user.id, "post_created")

      summary = ActivityService.get_user_activity_summary(user.id, 30)

      # 0 + 25
      assert summary.total_xp == 25
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
