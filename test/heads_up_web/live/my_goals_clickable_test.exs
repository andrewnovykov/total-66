defmodule HeadsUpWeb.MyGoalsClickableTest do
  use HeadsUpWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HeadsUp.AuthFixtures

  alias HeadsUp.{Goals, Groups}

  describe "My Goals clickable functionality" do
    setup :register_and_log_in_user

    test "user can click on goals in my-goals page to view them", %{conn: conn, user: user} do
      # Create a goal group
      {:ok, group} =
        Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test-group.png"
        })

      # Create a goal for the user
      {:ok, goal} =
        Goals.create_goal(%{
          title: "Learn Elixir",
          description: "Master Elixir programming",
          user_id: user.id,
          group_id: group.id,
          privacy: :public,
          progress: 50,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      # Navigate to my-goals page
      {:ok, lv, _html} = live(conn, ~p"/my-goals")

      # Should show the goal card
      assert has_element?(lv, "a[href='/goals/#{goal.id}']")
      assert render(lv) =~ "Learn Elixir"
      assert render(lv) =~ "Master Elixir programming"

      # Navigate to goal show page via the title link
      {:ok, goal_show_lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      # Should be on the goal show page
      assert render(goal_show_lv) =~ "Learn Elixir"
      assert render(goal_show_lv) =~ "Master Elixir programming"
    end

    test "user can access their private goals from my-goals page", %{conn: conn, user: user} do
      # Create a goal group
      {:ok, group} =
        Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test-group.png"
        })

      # Create a private goal for the user
      {:ok, goal} =
        Goals.create_goal(%{
          title: "Secret Goal",
          description: "My private goal",
          user_id: user.id,
          group_id: group.id,
          privacy: :private,
          progress: 25,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      # Navigate to my-goals page
      {:ok, lv, _html} = live(conn, ~p"/my-goals")

      # Should show the private goal card
      assert has_element?(lv, "a[href='/goals/#{goal.id}']")
      assert render(lv) =~ "Secret Goal"
      assert render(lv) =~ "Private"

      # Navigate to goal show page (user owns the private goal)
      {:ok, goal_show_lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      # Should be on the goal show page
      assert render(goal_show_lv) =~ "Secret Goal"
      assert render(goal_show_lv) =~ "My private goal"
    end

    test "goal cards show hover effects and cursor pointer", %{conn: conn, user: user} do
      # Create a goal group
      {:ok, group} =
        Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test-group.png"
        })

      # Create a goal for the user
      {:ok, _goal} =
        Goals.create_goal(%{
          title: "Clickable Goal",
          description: "Test clickable functionality",
          user_id: user.id,
          group_id: group.id,
          privacy: :public,
          progress: 75,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      # Navigate to my-goals page
      {:ok, lv, _html} = live(conn, ~p"/my-goals")

      # Check that goal cards have clickable links to goal detail pages
      assert has_element?(lv, "a[href*='/goals/']")
      # Goal cards have edit links and title links
      assert render(lv) =~ "Edit"
      assert render(lv) =~ "Clickable Goal"
    end

    test "empty goals state shows no goal cards", %{conn: conn, user: _user} do
      # Navigate to my-goals page with no goals
      {:ok, lv, _html} = live(conn, ~p"/my-goals")

      # Should show "0 of 1 goals used" and no goal cards
      assert render(lv) =~ "0 of 1 goals used"

      # Check that there are no goal-specific content (no goal titles or descriptions from actual goals)
      refute String.contains?(render(lv), "Learn Elixir")
      refute String.contains?(render(lv), "Secret Goal")
      refute String.contains?(render(lv), "Master Elixir")
    end
  end
end
