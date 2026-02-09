defmodule HeadsUp.FeedPrivacyTest do
  use HeadsUp.DataCase, async: true

  alias HeadsUp.{Accounts, FeedService, ActivityService}
  import HeadsUp.AuthFixtures
  import HeadsUp.ChallengesFixtures

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

      %{viewer: viewer, followed_user: followed_user}
    end

    test "non-challenge activities always visible (user_followed)", %{
      viewer: viewer,
      followed_user: followed_user
    } do
      {:ok, _} = ActivityService.track_activity(followed_user.id, "user_followed")

      feed = FeedService.get_user_feed(viewer.id)
      assert Enum.any?(feed, fn item -> item.activity_type == "user_followed" end)
    end
  end
end
