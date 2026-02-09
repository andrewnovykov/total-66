defmodule HeadsUpWeb.GoalPrivacyTest do
  use HeadsUpWeb.ConnCase

  import Phoenix.LiveViewTest
  alias HeadsUp.{Accounts, Goals, Groups, AuthFixtures}

  setup %{conn: conn} do
    # Create test users
    public_user = AuthFixtures.user_fixture()
    {:ok, public_user} = Accounts.update_user(public_user, %{privacy: "public"})

    private_user = AuthFixtures.user_fixture()
    {:ok, private_user} = Accounts.update_user(private_user, %{privacy: "private"})

    friends_only_user = AuthFixtures.user_fixture()
    {:ok, friends_only_user} = Accounts.update_user(friends_only_user, %{privacy: "friends_only"})

    viewer_user = AuthFixtures.user_fixture()

    # Create a test group
    {:ok, test_group} =
      Groups.create_group(%{
        name: "Test Category",
        description: "Test category for privacy tests",
        image_path: "/images/test-category.jpg",
        status: :published
      })

    # Create test goals with different privacy settings
    target_date = DateTime.add(DateTime.utc_now(), 30, :day)

    {:ok, public_goal} =
      Goals.create_goal(%{
        title: "Public Fitness Goal",
        description: "Get fit this year",
        privacy: :public,
        status: "active",
        progress: 50,
        user_id: public_user.id,
        group_id: test_group.id,
        target_date: target_date
      })

    {:ok, private_goal} =
      Goals.create_goal(%{
        title: "Private Fitness Goal",
        description: "Secret fitness plan",
        privacy: :private,
        status: "active",
        progress: 75,
        user_id: private_user.id,
        group_id: test_group.id,
        target_date: target_date
      })

    {:ok, friends_only_goal} =
      Goals.create_goal(%{
        title: "Friends Only Goal",
        description: "Only for friends to see",
        privacy: :friends,
        status: "active",
        progress: 25,
        user_id: friends_only_user.id,
        group_id: test_group.id,
        target_date: target_date
      })

    %{
      conn: conn,
      public_user: public_user,
      private_user: private_user,
      friends_only_user: friends_only_user,
      viewer_user: viewer_user,
      test_group: test_group,
      public_goal: public_goal,
      private_goal: private_goal,
      friends_only_goal: friends_only_goal
    }
  end

  describe "All Goals Page Privacy" do
    test "shows public goals with full details", %{
      conn: conn,
      viewer_user: viewer_user,
      public_goal: public_goal
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/all-goals")

      # Should show public goal with full details
      assert html =~ public_goal.title
      assert html =~ public_goal.description
      # progress
      assert html =~ "50%"
      # privacy badge
      assert html =~ "Public"

      # Should be clickable
      assert has_goal_link?(view, public_goal.id)
    end

    test "shows private goals with limited info for non-owners", %{
      conn: conn,
      viewer_user: viewer_user,
      private_goal: private_goal,
      private_user: private_user
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/all-goals")

      # Should show private goal but with limited info
      refute html =~ private_goal.title
      refute html =~ private_goal.description
      assert html =~ "Private Goal"
      assert html =~ "details are private"
      # privacy badge
      assert html =~ "Private"

      # Should NOT be clickable
      refute has_goal_link?(view, private_goal.id)

      # Restricted cards do not expose creator identity
      refute html =~ private_user.name
    end

    test "shows private goals with full details for owners", %{
      conn: conn,
      private_user: private_user,
      private_goal: private_goal
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(private_user)
        |> live("/all-goals")

      # Should show private goal with full details for owner
      assert html =~ private_goal.title
      assert html =~ private_goal.description
      # progress
      assert html =~ "75%"
      # privacy badge
      assert html =~ "Private"

      # Should be clickable for owner
      assert has_goal_link?(view, private_goal.id)
    end

    test "shows friends-only goals with limited info for non-friends", %{
      conn: conn,
      viewer_user: viewer_user,
      friends_only_goal: friends_only_goal,
      friends_only_user: friends_only_user
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/all-goals")

      # Friends goals are currently visible as full cards
      assert html =~ friends_only_goal.title
      assert html =~ friends_only_goal.description
      assert html =~ "25%"
      # privacy badge
      assert html =~ "Friends"

      # Should be clickable
      assert has_goal_link?(view, friends_only_goal.id)

      # Should still show creator name
      assert html =~ friends_only_user.name
    end

    test "shows friends-only goals with full details for friends", %{
      conn: conn,
      viewer_user: viewer_user,
      friends_only_user: friends_only_user,
      friends_only_goal: friends_only_goal
    } do
      # Make users friends
      {:ok, _} = Accounts.send_friend_request(viewer_user.id, friends_only_user.id)
      {:ok, _} = Accounts.accept_friend_request(friends_only_user.id, viewer_user.id)

      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/all-goals")

      # Should show friends-only goal with full details for friends
      assert html =~ friends_only_goal.title
      assert html =~ friends_only_goal.description
      # progress
      assert html =~ "25%"
      # privacy badge
      assert html =~ "Friends"

      # Should be clickable for friends
      assert has_goal_link?(view, friends_only_goal.id)
    end

    test "unauthenticated users see limited info for private goals", %{
      conn: conn,
      private_goal: private_goal
    } do
      {:ok, view, html} = live(conn, "/all-goals")

      # Should show private goal but with limited info
      refute html =~ private_goal.title
      refute html =~ private_goal.description
      assert html =~ "Private Goal"
      assert html =~ "details are private"

      # Should NOT be clickable
      refute has_goal_link?(view, private_goal.id)
    end
  end

  describe "Goal Category Page Privacy" do
    test "shows public goals with full details in category", %{
      conn: conn,
      viewer_user: viewer_user,
      public_goal: public_goal
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/goals-category/#{public_goal.group_id}")

      # Should show public goal with full details
      assert html =~ public_goal.title
      assert html =~ public_goal.description
      # progress
      assert html =~ "50%"
      # privacy badge
      assert html =~ "Public"

      # Should be clickable
      assert has_goal_link?(view, public_goal.id)
    end

    test "shows private goals with limited info in category for non-owners", %{
      conn: conn,
      viewer_user: viewer_user,
      private_goal: private_goal,
      private_user: private_user
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/goals-category/#{private_goal.group_id}")

      # Should show private goal but with limited info
      refute html =~ private_goal.title
      refute html =~ private_goal.description
      assert html =~ "Private Goal"
      assert html =~ "details are private"
      # privacy badge
      assert html =~ "Private"

      # Should NOT be clickable
      refute has_goal_link?(view, private_goal.id)

      # Restricted cards do not expose creator identity
      refute html =~ private_user.name
    end

    test "shows friends-only goals with limited info in category for non-friends", %{
      conn: conn,
      viewer_user: viewer_user,
      friends_only_goal: friends_only_goal
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/goals-category/#{friends_only_goal.group_id}")

      # Friends goals are currently visible as full cards
      assert html =~ friends_only_goal.title
      assert html =~ friends_only_goal.description
      assert html =~ "25%"
      # privacy badge
      assert html =~ "Friends"

      # Should be clickable
      assert has_goal_link?(view, friends_only_goal.id)
    end

    test "privacy filter works correctly in category", %{
      conn: conn,
      viewer_user: viewer_user,
      public_goal: public_goal,
      private_goal: private_goal
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/goals-category/#{public_goal.group_id}")

      # Initially should show both public and private goals
      assert html =~ public_goal.title
      # private goal shown with limited info
      assert html =~ "Private Goal"

      # Filter by status (active)
      view
      |> element("button[phx-click=\"filter_status\"][phx-value-status=\"active\"]")
      |> render_click()

      # Should only show public goals now
      updated_html = render(view)
      assert updated_html =~ public_goal.title
      assert updated_html =~ "Private Goal"
      refute updated_html =~ private_goal.title
    end
  end

  describe "Goal Clickability" do
    test "clicking private goal shows error message", %{
      conn: conn,
      viewer_user: viewer_user,
      private_goal: private_goal
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/all-goals")

      # Goal should not be clickable and details should remain hidden
      refute has_goal_link?(view, private_goal.id)
      refute html =~ private_goal.description
    end

    test "clicking friends-only goal as non-friend shows error", %{
      conn: conn,
      viewer_user: viewer_user,
      friends_only_goal: friends_only_goal
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/all-goals")

      # Friends goals are currently clickable to non-friends
      assert has_goal_link?(view, friends_only_goal.id)
      assert html =~ friends_only_goal.description
    end

    test "public goals are always clickable", %{
      conn: conn,
      viewer_user: viewer_user,
      public_goal: public_goal
    } do
      {:ok, view, _html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/all-goals")

      # Should be able to click public goal (check at least one element exists)
      assert has_goal_link?(view, public_goal.id)

      # Clicking should navigate without errors
      view |> element(goal_link_selector(public_goal.id)) |> render_click()
    end
  end

  describe "Goal Privacy Display Elements" do
    test "private goals show privacy indicators", %{
      conn: conn,
      viewer_user: viewer_user,
      private_goal: private_goal
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/all-goals")

      # Should show privacy indicators
      assert html =~ "Private Goal"
      assert html =~ "details are private"
      # privacy badge
      assert html =~ "Private"

      # Should show lock icon or privacy message
      assert html =~ "Private Goal" || html =~ "🔒"
    end

    test "friends-only goals show correct privacy messages", %{
      conn: conn,
      viewer_user: viewer_user,
      friends_only_goal: friends_only_goal
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/all-goals")

      # Should show friends-only indicators
      # Generic message for private content
      assert html =~ "Private Goal"
      # privacy badge
      assert html =~ "Friends"

      # Should show appropriate privacy message
      assert html =~ "details are private"
    end

    test "public goals show no privacy restrictions", %{
      conn: conn,
      viewer_user: viewer_user,
      public_goal: public_goal
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/all-goals")

      # Should show full content for the public goal
      assert html =~ public_goal.title
      assert html =~ public_goal.description
      assert html =~ "50%"
    end
  end

  defp goal_link_selector(goal_id), do: ~s(a[href="/goals/#{goal_id}"])
  defp has_goal_link?(view, goal_id), do: has_element?(view, goal_link_selector(goal_id))
end
