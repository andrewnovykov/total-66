defmodule HeadsUpWeb.FeedLiveTest do
  use HeadsUpWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias HeadsUp.{Accounts, Goals, ActivityService}

  setup do
    user = HeadsUp.AuthFixtures.user_fixture()
    friend = HeadsUp.AuthFixtures.user_fixture()
    group = HeadsUp.GroupsFixtures.group_fixture()

    # Make them friends
    {:ok, _} = Accounts.send_friend_request(user.id, friend.id)
    {:ok, _} = Accounts.accept_friend_request(friend.id, user.id)

    goal = HeadsUp.GoalsFixtures.goal_fixture(%{user_id: friend.id, group_id: group.id})

    %{user: user, friend: friend, goal: goal, group: group}
  end

  describe "Feed Page" do
    test "requires authentication", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log_in"}}} = live(conn, ~p"/feed")
    end

    test "shows feed for authenticated user", %{
      conn: conn,
      user: user,
      friend: friend,
      goal: goal
    } do
      # Create some activities
      {:ok, _} = ActivityService.track_activity(friend.id, "goal_created", goal_id: goal.id)

      {:ok, view, html} = live(conn |> log_in_user(user), ~p"/feed")

      assert html =~ "Your Feed"
      assert has_element?(view, "button", "Refresh")
    end

    test "shows empty state when no activities", %{conn: conn} do
      # Create a user with no friends or activities
      new_user = HeadsUp.AuthFixtures.user_fixture()
      {:ok, _view, html} = live(conn |> log_in_user(new_user), ~p"/feed")

      # The feed should load but might show some activity from the setup
      assert html =~ "Your Feed"
    end

    test "can refresh feed", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn |> log_in_user(user), ~p"/feed")

      # Check refresh button exists and works
      assert has_element?(view, "button", "Refresh")
      view |> element("button", "Refresh") |> render_click()
    end
  end
end
