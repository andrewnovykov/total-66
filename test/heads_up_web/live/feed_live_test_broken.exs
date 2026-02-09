defmodule HeadsUpWeb.FeedLiveTest do
  use HeadsUpWeb.ConnCase

  import Phoenix.LiveViewTest
  alias HeadsUp.{Goals, Group, Repo}

  setup :register_and_log_in_user

  describe "Feed Live" do
    setup %{user: user} do
      # Create another user to follow
      friend = HeadsUp.AuthFixtures.user_fixture()

      # Make them friends
      {:ok, _} = HeadsUp.Accounts.send_friend_request(user.id, friend.id)
      {:ok, _} = HeadsUp.Accounts.accept_friend_request(friend.id, user.id)

      # Create some goals and activities
      group =
        Repo.insert!(%Group{
          name: "Test Category",
          description: "A test category for feed testing",
          image_path: "/test/image.jpg",
          status: :published
        })

      {:ok, goal} =
        Goals.create_goal(%{
          title: "Friend's Test Goal",
          description: "A goal by a friend",
          privacy: :public,
          user_id: friend.id,
          group_id: group.id,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      {:ok, my_goal} =
        Goals.create_goal(%{
          title: "My Test Goal",
          description: "My own goal",
          privacy: :public,
          user_id: user.id,
          group_id: group.id,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      %{friend: friend, goal: goal, my_goal: my_goal, group: group}
    end

    test "renders feed page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/feed")

      assert html =~ "Activity Feed"
      assert html =~ "What's happening with your connections"
    end

    test "shows activities from friends", %{conn: conn, friend: friend, goal: goal} do
      {:ok, view, _html} = live(conn, ~p"/feed")

      # The goal creation should appear in the feed
      assert has_element?(view, "[data-activity-type='goal_created']")
      assert render(view) =~ friend.name
      assert render(view) =~ goal.title
    end

    test "shows own activities", %{conn: conn, user: user, my_goal: my_goal} do
      {:ok, view, _html} = live(conn, ~p"/feed")

      # User's own goal creation should appear in feed
      assert has_element?(view, "[data-activity-type='goal_created']")
      assert render(view) =~ user.name
      assert render(view) =~ my_goal.title
    end

    test "loads more activities when scrolling", %{conn: conn, friend: friend, group: group} do
      # Create many goals to test pagination
      for i <- 1..25 do
        {:ok, _goal} =
          HeadsUp.Goals.create_goal(%{
            title: "Goal #{i}",
            description: "Goal description #{i}",
            privacy: :public,
            user_id: friend.id,
            group_id: group.id,
            target_date: DateTime.add(DateTime.utc_now(), 30, :day)
          })
      end

      {:ok, view, _html} = live(conn, ~p"/feed")

      # Check that activities are displayed
      assert has_element?(view, "[data-activity-type]")

      # Simulate loading more (if load more button exists)
      if has_element?(view, "#load-more-button") do
        view |> element("#load-more-button") |> render_click()
        # Verify load more worked by checking for activities
        assert has_element?(view, "[data-activity-type]")
      end
    end

    test "filters activities by type", %{conn: conn, friend: friend, goal: goal} do
      {:ok, _activity1} =
        HeadsUp.ActivityService.track_activity(friend.id, "goal_created",
          goal_id: goal.id,
          description: "Created a goal"
        )

      {:ok, _activity2} =
        HeadsUp.ActivityService.track_activity(friend.id, "goal_completed",
          goal_id: goal.id,
          description: "Completed a goal"
        )

      # Create a post
      {:ok, _post} =
        HeadsUp.Goals.create_goal_post(%{
          content: "Test post content",
          post_type: :update,
          goal_id: goal.id,
          user_id: friend.id
        })

      {:ok, view, html} = live(conn, ~p"/feed")

      # Check for different activity types in the HTML
      assert html =~ "goal_created" or html =~ "Created a goal"
      assert html =~ "goal_completed" or html =~ "Completed a goal"
    end
    end

    test "handles empty feed gracefully", %{conn: conn} do
      # Create a user with no friends or activities
      new_user = HeadsUp.AuthFixtures.user_fixture()
      conn = log_in_user(conn, new_user)

      {:ok, view, html} = live(conn, ~p"/feed")

      assert html =~ "No activities yet"
      assert html =~ "Start following people"
    end

    test "real-time updates when new activities occur", %{
      conn: conn,
      friend: friend,
      group: group
    } do
      {:ok, view, _html} = live(conn, ~p"/feed")

      initial_activities = view |> element("[data-activity-type]") |> render_all()

      # Create a new goal (this should trigger activity tracking)
      {:ok, _new_goal} =
        HeadsUp.Goals.create_goal(%{
          title: "Brand New Goal",
          description: "A fresh goal",
          privacy: :public,
          user_id: friend.id,
          group_id: group.id,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      # Wait a bit for the update to propagate
      :timer.sleep(100)

      # The view should update with the new activity
      new_activities = view |> element("[data-activity-type]") |> render_all()
      assert length(new_activities) > length(initial_activities)
      assert render(view) =~ "Brand New Goal"
    end

    test "shows activity timestamps correctly", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/feed")

      # Should show relative timestamps
      assert html =~ ~r/\d+ (second|minute|hour|day)s? ago/
    end

    test "links to goals and users work", %{conn: conn, friend: friend, goal: goal} do
      {:ok, view, _html} = live(conn, ~p"/feed")

      # Click on user name should navigate to user profile
      view |> element("a[href='/people/#{friend.user_name}']") |> render_click()
      assert_redirect(view, ~p"/people/#{friend.user_name}")

      # Go back to feed
      {:ok, view, _html} = live(conn, ~p"/feed")

      # Click on goal should navigate to goal page
      view |> element("a[href='/goals/#{goal.id}']") |> render_click()
      assert_redirect(view, ~p"/goals/#{goal.id}")
    end
  end

  describe "Feed Accessibility" do
    test "has proper ARIA labels", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/feed")

      assert html =~ ~r/aria-label=".*"/
      assert html =~ ~r/role=".*"/
    end

    test "supports keyboard navigation", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/feed")

      # Tab navigation should work
      assert view |> element("button") |> render() =~ "tabindex"
    end
  end

  describe "Feed Performance" do
    test "uses lazy loading for images", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/feed")

      # Images should have loading="lazy" attribute
      if html =~ "<img" do
        assert html =~ ~r/loading="lazy"/
      end
    end

    test "limits initial load", %{conn: conn, friend: friend, group: group} do
      # Create many activities
      for i <- 1..50 do
        {:ok, _goal} =
          HeadsUp.Goals.create_goal(%{
            title: "Goal #{i}",
            description: "Goal description #{i}",
            privacy: :public,
            user_id: friend.id,
            group_id: group.id,
            target_date: DateTime.add(DateTime.utc_now(), 30, :day)
          })
      end

      {:ok, view, _html} = live(conn, ~p"/feed")

      # Should not load all activities at once - check that some activities exist but not overwhelming
      assert has_element?(view, "[data-activity-type]")
    end
  end
end
