defmodule HeadsUp.GoalSubscriptionTest do
  use HeadsUp.DataCase, async: true

  alias HeadsUp.{Goals, Accounts}
  import HeadsUp.AuthFixtures
  import HeadsUp.GroupsFixtures

  describe "subscribe_to_goal/2" do
    setup do
      owner = user_fixture()
      friend = user_fixture()
      stranger = user_fixture()

      group = group_fixture()

      # Establish friendship
      {:ok, _} = Accounts.send_friend_request(friend.id, owner.id)
      {:ok, _} = Accounts.accept_friend_request(owner.id, friend.id)

      {:ok, public_goal} =
        Goals.create_goal(%{
          title: "Public Goal",
          description: "Public",
          status: :active,
          privacy: :public,
          user_id: owner.id,
          group_id: group.id,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      {:ok, private_goal} =
        Goals.create_goal(%{
          title: "Private Goal",
          description: "Private",
          status: :active,
          privacy: :private,
          user_id: owner.id,
          group_id: group.id,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      {:ok, friends_goal} =
        Goals.create_goal(%{
          title: "Friends Goal",
          description: "Friends Only",
          status: :active,
          privacy: :friends,
          user_id: owner.id,
          group_id: group.id,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      %{
        owner: owner,
        friend: friend,
        stranger: stranger,
        public_goal: public_goal,
        private_goal: private_goal,
        friends_goal: friends_goal
      }
    end

    test "user can subscribe to public goal", %{public_goal: goal, stranger: stranger} do
      assert {:ok, subscription} = Goals.subscribe_to_goal(goal.id, stranger.id)
      assert subscription.goal_id == goal.id
      assert subscription.user_id == stranger.id
    end

    test "user cannot subscribe to private goal", %{private_goal: goal, stranger: stranger} do
      assert {:error, :access_denied} = Goals.subscribe_to_goal(goal.id, stranger.id)
    end

    test "owner cannot subscribe to own goal", %{public_goal: goal, owner: owner} do
      assert {:error, :cannot_subscribe_to_own_goal} = Goals.subscribe_to_goal(goal.id, owner.id)
    end

    test "stranger cannot subscribe to friends-only goal", %{
      friends_goal: goal,
      stranger: stranger
    } do
      assert {:error, :must_be_friends} = Goals.subscribe_to_goal(goal.id, stranger.id)
    end

    test "friend can subscribe to friends-only goal", %{friends_goal: goal, friend: friend} do
      assert {:ok, subscription} = Goals.subscribe_to_goal(goal.id, friend.id)
      assert subscription.goal_id == goal.id
      assert subscription.user_id == friend.id
    end
  end
end
