defmodule HeadsUp.FeedPrivacyTest do
  use HeadsUp.DataCase, async: true

  alias HeadsUp.{Accounts, Goals, FeedService, ActivityService}
  import HeadsUp.AuthFixtures
  import HeadsUp.GoalsFixtures
  import HeadsUp.ChallengesFixtures

  describe "feed privacy filtering - goals" do
    setup do
      viewer = user_fixture()
      followed_user = user_fixture()
      friend = user_fixture()
      stranger = user_fixture()

      # viewer follows followed_user
      {:ok, _} = Accounts.follow_user(viewer.id, followed_user.id)

      # viewer and friend are friends
      {:ok, _} = Accounts.send_friend_request(viewer.id, friend.id)
      {:ok, _} = Accounts.accept_friend_request(friend.id, viewer.id)

      %{viewer: viewer, followed_user: followed_user, friend: friend, stranger: stranger}
    end

    test "shows public goal activities from followed users", %{
      viewer: viewer,
      followed_user: followed_user
    } do
      goal = goal_fixture(%{user_id: followed_user.id, privacy: :public})

      {:ok, _} =
        ActivityService.track_activity(followed_user.id, "goal_created", goal_id: goal.id)

      feed = FeedService.get_user_feed(viewer.id)

      assert Enum.any?(feed, fn item ->
               item.activity_type == "goal_created" && item.goal && item.goal.id == goal.id
             end)
    end

    test "hides private goal activities from followed users", %{
      viewer: viewer,
      followed_user: followed_user
    } do
      goal = goal_fixture(%{user_id: followed_user.id, privacy: :private})

      {:ok, _} =
        ActivityService.track_activity(followed_user.id, "goal_created", goal_id: goal.id)

      feed = FeedService.get_user_feed(viewer.id)
      refute Enum.any?(feed, fn item -> item.goal && item.goal.id == goal.id end)
    end

    test "hides friends-only goal activities from non-friend followed users", %{
      viewer: viewer,
      followed_user: followed_user
    } do
      goal = goal_fixture(%{user_id: followed_user.id, privacy: :friends})

      {:ok, _} =
        ActivityService.track_activity(followed_user.id, "goal_created", goal_id: goal.id)

      feed = FeedService.get_user_feed(viewer.id)
      refute Enum.any?(feed, fn item -> item.goal && item.goal.id == goal.id end)
    end

    test "shows friends-only goal activities from friends", %{viewer: viewer, friend: friend} do
      goal = goal_fixture(%{user_id: friend.id, privacy: :friends})
      {:ok, _} = ActivityService.track_activity(friend.id, "goal_created", goal_id: goal.id)

      # viewer needs to follow friend for activities to appear
      {:ok, _} = Accounts.follow_user(viewer.id, friend.id)

      feed = FeedService.get_user_feed(viewer.id)

      assert Enum.any?(feed, fn item ->
               item.activity_type == "goal_created" && item.goal && item.goal.id == goal.id
             end)
    end

    test "own private goal activities are visible in own feed", %{viewer: viewer} do
      goal = goal_fixture(%{user_id: viewer.id, privacy: :private})
      {:ok, _} = ActivityService.track_activity(viewer.id, "goal_created", goal_id: goal.id)

      feed = FeedService.get_user_feed(viewer.id)

      assert Enum.any?(feed, fn item ->
               item.activity_type == "goal_created" && item.goal && item.goal.id == goal.id
             end)
    end

    test "shows post activities for public goals", %{viewer: viewer, followed_user: followed_user} do
      goal = goal_fixture(%{user_id: followed_user.id, privacy: :public})

      {:ok, _} =
        ActivityService.track_activity(followed_user.id, "post_created", goal_id: goal.id)

      feed = FeedService.get_user_feed(viewer.id)

      assert Enum.any?(feed, fn item ->
               item.activity_type == "post_created" && item.goal && item.goal.id == goal.id
             end)
    end

    test "hides post activities for private goals", %{
      viewer: viewer,
      followed_user: followed_user
    } do
      goal = goal_fixture(%{user_id: followed_user.id, privacy: :private})

      {:ok, _} =
        ActivityService.track_activity(followed_user.id, "post_created", goal_id: goal.id)

      feed = FeedService.get_user_feed(viewer.id)
      refute Enum.any?(feed, fn item -> item.goal && item.goal.id == goal.id end)
    end
  end

  describe "feed privacy filtering - challenges" do
    setup do
      viewer = user_fixture()
      followed_user = user_fixture()
      friend = user_fixture()

      {:ok, _} = Accounts.follow_user(viewer.id, followed_user.id)
      {:ok, _} = Accounts.send_friend_request(viewer.id, friend.id)
      {:ok, _} = Accounts.accept_friend_request(friend.id, viewer.id)

      %{viewer: viewer, followed_user: followed_user, friend: friend}
    end

    test "shows public challenge activities from followed users", %{
      viewer: viewer,
      followed_user: followed_user
    } do
      challenge = challenge_fixture(%{user: followed_user, visibility: :public})

      {:ok, _} =
        ActivityService.track_activity(followed_user.id, "challenge_created",
          challenge_id: challenge.id
        )

      feed = FeedService.get_user_feed(viewer.id)

      assert Enum.any?(feed, fn item ->
               item.activity_type == "challenge_created" && item.challenge &&
                 item.challenge.id == challenge.id
             end)
    end

    test "hides private challenge activities from followed users", %{
      viewer: viewer,
      followed_user: followed_user
    } do
      challenge = challenge_fixture(%{user: followed_user, visibility: :private})

      {:ok, _} =
        ActivityService.track_activity(followed_user.id, "challenge_created",
          challenge_id: challenge.id
        )

      feed = FeedService.get_user_feed(viewer.id)
      refute Enum.any?(feed, fn item -> item.challenge && item.challenge.id == challenge.id end)
    end

    test "shows friends-only challenge activities from friends", %{viewer: viewer, friend: friend} do
      challenge = challenge_fixture(%{user: friend, visibility: :friends})

      {:ok, _} =
        ActivityService.track_activity(friend.id, "challenge_created", challenge_id: challenge.id)

      # Viewer needs to follow friend for activities to show
      {:ok, _} = Accounts.follow_user(viewer.id, friend.id)

      feed = FeedService.get_user_feed(viewer.id)

      assert Enum.any?(feed, fn item ->
               item.activity_type == "challenge_created" && item.challenge &&
                 item.challenge.id == challenge.id
             end)
    end

    test "hides friends-only challenge activities from non-friend followed users", %{
      viewer: viewer,
      followed_user: followed_user
    } do
      challenge = challenge_fixture(%{user: followed_user, visibility: :friends})

      {:ok, _} =
        ActivityService.track_activity(followed_user.id, "challenge_created",
          challenge_id: challenge.id
        )

      feed = FeedService.get_user_feed(viewer.id)
      refute Enum.any?(feed, fn item -> item.challenge && item.challenge.id == challenge.id end)
    end
  end

  describe "feed activity types" do
    setup do
      viewer = user_fixture()
      followed_user = user_fixture()
      {:ok, _} = Accounts.follow_user(viewer.id, followed_user.id)

      goal = goal_fixture(%{user_id: followed_user.id, privacy: :public})

      %{viewer: viewer, followed_user: followed_user, goal: goal}
    end

    test "shows goal_updated activities", %{
      viewer: viewer,
      followed_user: followed_user,
      goal: goal
    } do
      {:ok, _} =
        ActivityService.track_activity(followed_user.id, "goal_updated", goal_id: goal.id)

      feed = FeedService.get_user_feed(viewer.id)
      assert Enum.any?(feed, fn item -> item.activity_type == "goal_updated" end)
    end

    test "shows post_liked activities", %{
      viewer: viewer,
      followed_user: followed_user,
      goal: goal
    } do
      {:ok, _} = ActivityService.track_activity(followed_user.id, "post_liked", goal_id: goal.id)

      feed = FeedService.get_user_feed(viewer.id)
      assert Enum.any?(feed, fn item -> item.activity_type == "post_liked" end)
    end

    test "shows goal_step_completed activities", %{
      viewer: viewer,
      followed_user: followed_user,
      goal: goal
    } do
      {:ok, _} =
        ActivityService.track_activity(followed_user.id, "goal_step_completed", goal_id: goal.id)

      feed = FeedService.get_user_feed(viewer.id)
      assert Enum.any?(feed, fn item -> item.activity_type == "goal_step_completed" end)
    end

    test "non-goal/non-challenge activities always visible (user_followed)", %{
      viewer: viewer,
      followed_user: followed_user
    } do
      {:ok, _} = ActivityService.track_activity(followed_user.id, "user_followed")

      feed = FeedService.get_user_feed(viewer.id)
      assert Enum.any?(feed, fn item -> item.activity_type == "user_followed" end)
    end
  end
end
