defmodule HeadsUpWeb.Bug2FailedGoalRestrictionsTest do
  use HeadsUpWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HeadsUp.AuthFixtures
  import HeadsUp.GoalsFixtures

  alias HeadsUp.Goals

  describe "BUG-2 regression: failed goals cannot be frozen" do
    setup :register_and_log_in_user

    test "freeze button is hidden on show page for failed goals", %{conn: conn, user: user} do
      goal = goal_fixture(%{user_id: user.id})
      {:ok, _failed_goal} = Goals.fail_goal(goal, "Changed priorities")

      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      refute has_element?(lv, "button", "Freeze Goal")
      refute has_element?(lv, "button", "Edit Goal Details")
    end

    test "freeze button is hidden on my-goals page for failed goals", %{conn: conn, user: user} do
      goal = goal_fixture(%{user_id: user.id})
      {:ok, _failed_goal} = Goals.fail_goal(goal, "Changed priorities")

      {:ok, lv, _html} = live(conn, ~p"/my-goals")

      refute has_element?(lv, "button", "Freeze")
      assert render(lv) =~ goal.title
    end

    test "backend rejects freeze on failed goal", %{user: user} do
      goal = goal_fixture(%{user_id: user.id})
      {:ok, failed_goal} = Goals.fail_goal(goal, "Changed priorities")

      assert {:error, :failed} = Goals.freeze_goal_with_ownership(failed_goal, user.id)
    end
  end

  describe "BUG-2 regression: failed goals cannot be edited" do
    setup :register_and_log_in_user

    test "edit button is hidden on show page for failed goals", %{conn: conn, user: user} do
      goal = goal_fixture(%{user_id: user.id})
      {:ok, _failed_goal} = Goals.fail_goal(goal, "Lost interest")

      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      refute has_element?(lv, "button", "Edit Goal Details")
    end

    test "edit link is hidden on my-goals page for failed goals", %{conn: conn, user: user} do
      goal = goal_fixture(%{user_id: user.id})
      {:ok, _failed_goal} = Goals.fail_goal(goal, "Lost interest")

      {:ok, lv, _html} = live(conn, ~p"/my-goals")

      refute has_element?(lv, "a[href='/goals/#{goal.id}/edit']")
      assert render(lv) =~ goal.title
    end

    test "direct navigation to edit page redirects for failed goals", %{conn: conn, user: user} do
      goal = goal_fixture(%{user_id: user.id})
      {:ok, _failed_goal} = Goals.fail_goal(goal, "Lost interest")

      assert {:error,
              {:live_redirect,
               %{to: "/my-goals", flash: %{"error" => "Failed goals cannot be edited"}}}} =
               live(conn, ~p"/goals/#{goal.id}/edit")
    end

    test "edit page loads for active goals (no regression)", %{conn: conn, user: user} do
      goal = goal_fixture(%{user_id: user.id})

      {:ok, _lv, html} = live(conn, ~p"/goals/#{goal.id}/edit")

      assert html =~ "Edit Goal"
      assert html =~ goal.title
    end
  end

  describe "BUG-2 edge cases" do
    setup :register_and_log_in_user

    test "completed goals also cannot be edited or frozen on show page", %{conn: conn, user: user} do
      goal = goal_fixture(%{user_id: user.id, progress: 100})

      {:ok, _completed_goal} =
        goal
        |> Ecto.Changeset.change(%{status: :completed})
        |> HeadsUp.Repo.update()

      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      refute has_element?(lv, "button", "Freeze Goal")
      refute has_element?(lv, "button", "Edit Goal Details")
    end

    test "active goals still show freeze and edit buttons", %{conn: conn, user: user} do
      goal = goal_fixture(%{user_id: user.id})

      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      assert has_element?(lv, "button", "Freeze Goal")
      assert has_element?(lv, "button", "Edit Goal Details")
    end

    test "frozen goals still show unfreeze and edit buttons", %{conn: conn, user: user} do
      goal = goal_fixture(%{user_id: user.id})
      {:ok, _frozen_goal} = Goals.freeze_goal(goal)

      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      assert has_element?(lv, "button", "Unfreeze Goal")
      assert has_element?(lv, "button", "Edit Goal Details")
    end
  end
end
