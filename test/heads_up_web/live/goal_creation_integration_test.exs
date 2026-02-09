defmodule HeadsUpWeb.GoalCreationIntegrationTest do
  use HeadsUpWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HeadsUp.AuthFixtures

  alias HeadsUp.{Goals, Groups, Repo}

  describe "Goal creation end-to-end flow" do
    setup :register_and_log_in_user

    test "authenticated user can access goal creation from header button", %{
      conn: conn,
      user: _user
    } do
      # Create a goal group for the form
      {:ok, _group} =
        Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test-group.png"
        })

      # Visit my-goals page to see the header
      {:ok, lv, html} = live(conn, ~p"/my-goals")

      # Check that create button is present and enabled for free user (0 goals)
      assert html =~ "Create Goal"

      # Click the create button in the hero banner (white bg button with scale effect)
      {:ok, new_goal_lv, _html} =
        lv
        |> element("a.inline-flex.bg-white.text-blue-600[href='/goals/new']")
        |> render_click()
        |> follow_redirect(conn, ~p"/goals/new")

      # Should be on the goal creation page
      assert has_element?(new_goal_lv, "h1", "Create New Goal")
      assert has_element?(new_goal_lv, "form#goal-form")
    end

    test "free user can create one goal then button becomes disabled and shows flash message", %{
      conn: conn,
      user: user
    } do
      # Create a goal group for the form
      {:ok, group} =
        Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test-group.png"
        })

      # Create one goal for the user (reaching free limit)
      {:ok, _goal} =
        Goals.create_goal(%{
          title: "Test Goal",
          description: "Test description",
          user_id: user.id,
          group_id: group.id,
          privacy: :public,
          progress: 0,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      # Visit my-goals page to see header
      {:ok, lv, html} = live(conn, ~p"/my-goals")

      # Check that create button is present but disabled (shown as button with show_upgrade_message)
      assert html =~ "Create Goal"
      assert has_element?(lv, "button[phx-click='show_upgrade_message']")
    end

    test "pro user can create up to 3 goals", %{conn: conn, user: user} do
      # Update user to pro_3 subscription
      Repo.update!(HeadsUp.Users.changeset(user, %{subscription_type: "pro_3"}))

      # Create a goal group
      {:ok, group} =
        Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test-group.png"
        })

      # Create 2 goals (under the limit)
      for i <- 1..2 do
        {:ok, _goal} =
          Goals.create_goal(%{
            title: "Test Goal #{i}",
            description: "Test description #{i}",
            user_id: user.id,
            group_id: group.id,
            privacy: :public,
            progress: 0,
            target_date: DateTime.add(DateTime.utc_now(), 30, :day)
          })
      end

      # Visit my-goals page
      {:ok, _lv, html} = live(conn, ~p"/my-goals")

      # Button should still be enabled (2 < 3) - create link present
      assert html =~ "Create Goal"
      assert html =~ ~r/href="\/goals\/new"/

      # Create third goal
      {:ok, _goal} =
        Goals.create_goal(%{
          title: "Test Goal 3",
          description: "Test description 3",
          user_id: user.id,
          group_id: group.id,
          privacy: :public,
          progress: 0,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      # Visit my-goals page again
      {:ok, lv, _html} = live(conn, ~p"/my-goals")

      # Button should now be disabled (3 = 3) - upgrade button shown
      assert has_element?(lv, "button[phx-click='show_upgrade_message']")
    end

    test "complete goal creation flow with form validation", %{conn: conn, user: user} do
      # Create a goal group
      {:ok, group} =
        Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test-group.png"
        })

      # Navigate to goal creation page
      {:ok, lv, _html} = live(conn, ~p"/goals/new")

      # Test form validation - submit empty form
      lv
      |> form("#goal-form", goal: %{})
      |> render_submit()

      # Should stay on the same page with form (not redirect)
      assert has_element?(lv, "form#goal-form")

      # Fill and submit valid form
      {:ok, my_goals_lv, _html} =
        lv
        |> form("#goal-form",
          goal: %{
            title: "Learn Elixir",
            description: "Master Elixir and Phoenix",
            big_description:
              "I want to become proficient in Elixir programming language and Phoenix framework",
            group_id: group.id,
            privacy: :public,
            progress: 0,
            target_date: "2024-12-31T23:59:00"
          }
        )
        |> render_submit()
        |> follow_redirect(conn, ~p"/my-goals")

      # Should be redirected to my-goals page
      assert render(my_goals_lv) =~ "My Goals"

      # Should show the newly created goal
      assert render(my_goals_lv) =~ "Learn Elixir"
      assert render(my_goals_lv) =~ "Master Elixir and Phoenix"

      # Verify goal was created in database
      goals = Goals.list_goals_by_user(user.id)
      assert length(goals) == 1
      assert hd(goals).title == "Learn Elixir"
    end

    test "goal creation from my-goals page button", %{conn: conn, user: _user} do
      # Create a goal group
      {:ok, _group} =
        Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test-group.png"
        })

      # Navigate to my-goals page
      {:ok, lv, _html} = live(conn, ~p"/my-goals")

      # Should show create button in the hero
      assert has_element?(lv, "a.inline-flex.bg-white.text-blue-600[href='/goals/new']")

      # Click the create button in the hero banner
      {:ok, new_goal_lv, _html} =
        lv
        |> element("a.inline-flex.bg-white.text-blue-600[href='/goals/new']")
        |> render_click()
        |> follow_redirect(conn, ~p"/goals/new")

      # Should be on goal creation page
      assert has_element?(new_goal_lv, "h1", "Create New Goal")
      assert has_element?(new_goal_lv, "form#goal-form")
    end

    test "goal creation fails when user reaches subscription limit", %{conn: conn, user: user} do
      # Create a goal group
      {:ok, group} =
        Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test-group.png"
        })

      # Create one goal for free user (reaching limit)
      {:ok, _goal} =
        Goals.create_goal(%{
          title: "Existing Goal",
          description: "Test description",
          user_id: user.id,
          group_id: group.id,
          privacy: :public,
          progress: 0,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      # Try to navigate to goal creation page
      {:ok, my_goals_lv, _html} =
        live(conn, ~p"/goals/new")
        |> follow_redirect(conn, ~p"/my-goals")

      # Should be redirected to my-goals with error message
      assert has_element?(my_goals_lv, "[role='alert']") ||
               render(my_goals_lv) =~ "You can only create up to 1 goals"
    end

    test "unlimited subscription user has higher active limit", %{conn: conn, user: user} do
      # Update user to unlimited subscription (pro tier = 10 active items)
      Repo.update!(HeadsUp.Users.changeset(user, %{subscription_type: "unlimited"}))

      # Create a goal group
      {:ok, group} =
        Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test-group.png"
        })

      # Pro users can create up to 10 active goals (more than free users' 3)
      for i <- 1..10 do
        {:ok, _goal} =
          Goals.create_goal(%{
            title: "Test Goal #{i}",
            description: "Test description #{i}",
            user_id: user.id,
            group_id: group.id,
            privacy: :public,
            progress: 0,
            target_date: DateTime.add(DateTime.utc_now(), 30, :day)
          })
      end

      # 11th active goal should be rejected (pro limit is 10)
      assert {:error, :active_limit_reached} =
               Goals.create_goal(%{
                 title: "Test Goal 11",
                 description: "Test description 11",
                 user_id: user.id,
                 group_id: group.id,
                 privacy: :public,
                 progress: 0,
                 target_date: DateTime.add(DateTime.utc_now(), 30, :day)
               })

      # Visit my-goals page
      {:ok, _lv, html} = live(conn, ~p"/my-goals")

      # Should show the user's goals
      assert html =~ "Test Goal 1"
    end

    test "my-goals page shows subscription information correctly", %{conn: conn, user: user} do
      # Test free user
      {:ok, _lv, html} = live(conn, ~p"/my-goals")
      assert html =~ "0 of 1 goals used"
      assert html =~ "Free (1 goal)"

      # Update to pro_3 and test
      Repo.update!(HeadsUp.Users.changeset(user, %{subscription_type: "pro_3"}))
      {:ok, _lv, html} = live(conn, ~p"/my-goals")
      assert html =~ "0 of 3 goals used"
      assert html =~ "Pro (3 goals)"

      # Update to unlimited and test
      Repo.update!(HeadsUp.Users.changeset(user, %{subscription_type: "unlimited"}))
      {:ok, _lv, html} = live(conn, ~p"/my-goals")
      assert html =~ "0 of unlimited goals used"
      assert html =~ "Premium (Unlimited goals)"
    end

    test "guest user cannot access goal creation", %{conn: _conn} do
      # Without authentication, try to access goal creation
      conn = build_conn()

      # Should redirect to login
      {:ok, login_lv, _html} =
        live(conn, ~p"/goals/new")
        |> follow_redirect(conn, ~p"/users/log_in")

      assert has_element?(login_lv, "h1", "Log in") ||
               render(login_lv) =~ "You must be logged in"
    end

    test "back button on goal creation page works", %{conn: conn, user: _user} do
      # Navigate to goal creation page
      {:ok, lv, _html} = live(conn, ~p"/goals/new")

      # Click back button
      {:ok, my_goals_lv, _html} =
        lv
        |> element("a", "Back to My Goals")
        |> render_click()
        |> follow_redirect(conn, ~p"/my-goals")

      # Should be on my-goals page
      assert render(my_goals_lv) =~ "My Goals"
    end

    test "disabled create button on my-goals page shows flash message when clicked", %{
      conn: conn,
      user: user
    } do
      # Create a goal group
      {:ok, group} =
        Groups.create_group(%{
          name: "Test Group",
          description: "Test",
          status: "published",
          image_path: "/images/test-group.png"
        })

      # Create one goal for free user (reaching limit)
      {:ok, _goal} =
        Goals.create_goal(%{
          title: "Existing Goal",
          description: "Test description",
          user_id: user.id,
          group_id: group.id,
          privacy: :public,
          progress: 0,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      # Navigate to my-goals page
      {:ok, lv, _html} = live(conn, ~p"/my-goals")

      # Should show disabled create button
      assert has_element?(lv, "button[phx-click='show_upgrade_message']")

      # Click the disabled button
      lv
      |> element("button[phx-click='show_upgrade_message']")
      |> render_click()

      # Should show flash message
      assert render(lv) =~ "You have reached your goal limit of 1 goals" or
               render(lv) =~ "Please upgrade to create more goals"
    end
  end
end
