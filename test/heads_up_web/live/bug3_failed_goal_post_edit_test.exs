defmodule HeadsUpWeb.Bug3FailedGoalPostEditTest do
  use HeadsUpWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HeadsUp.GoalsFixtures

  alias HeadsUp.Goals

  describe "BUG-3 regression: post edit/delete blocked on failed goals" do
    setup :register_and_log_in_user

    test "post edit/delete buttons hidden on failed goal show page", %{conn: conn, user: user} do
      goal = goal_fixture(%{user_id: user.id})

      _post =
        goal_post_fixture(%{user_id: user.id, goal_id: goal.id, content: "My progress update"})

      {:ok, _failed_goal} = Goals.fail_goal(goal, "Changed priorities")

      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      # Posts should still be visible (read-only)
      assert render(lv) =~ "My progress update"

      # Edit and delete buttons should NOT be visible
      refute has_element?(lv, "button[title='Edit post']")
      refute has_element?(lv, "button[title='Delete post']")
    end

    test "post edit/delete buttons visible on active goal", %{conn: conn, user: user} do
      goal = goal_fixture(%{user_id: user.id})

      _post =
        goal_post_fixture(%{user_id: user.id, goal_id: goal.id, content: "Active goal post"})

      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      assert render(lv) =~ "Active goal post"
      assert has_element?(lv, "button[title='Edit post']")
      assert has_element?(lv, "button[title='Delete post']")
    end

    test "create post form hidden on failed goal", %{conn: conn, user: user} do
      goal = goal_fixture(%{user_id: user.id})
      {:ok, _failed_goal} = Goals.fail_goal(goal, "Changed priorities")

      {:ok, _lv, html} = live(conn, ~p"/goals/#{goal.id}")

      refute html =~ "Share an Update"
    end

    test "create post form visible on active goal", %{conn: conn, user: user} do
      goal = goal_fixture(%{user_id: user.id})

      {:ok, _lv, html} = live(conn, ~p"/goals/#{goal.id}")

      assert html =~ "Share an Update"
    end

    test "edit_post event rejected on failed goal", %{conn: conn, user: user} do
      goal = goal_fixture(%{user_id: user.id})
      post = goal_post_fixture(%{user_id: user.id, goal_id: goal.id, content: "Before failure"})
      {:ok, _failed_goal} = Goals.fail_goal(goal, "Changed priorities")

      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      # Try to trigger edit_post event directly
      html = render_click(lv, "edit_post", %{"post-id" => to_string(post.id)})

      assert html =~ "Cannot edit posts on a failed goal"
    end

    test "delete_post event rejected on failed goal", %{conn: conn, user: user} do
      goal = goal_fixture(%{user_id: user.id})
      post = goal_post_fixture(%{user_id: user.id, goal_id: goal.id, content: "Before failure"})
      {:ok, _failed_goal} = Goals.fail_goal(goal, "Changed priorities")

      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      # Try to trigger delete_post event directly
      html = render_click(lv, "delete_post", %{"post-id" => to_string(post.id)})

      assert html =~ "Cannot delete posts on a failed goal"
    end
  end
end
