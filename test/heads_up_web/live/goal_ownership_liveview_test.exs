defmodule HeadsUpWeb.GoalOwnershipLiveViewTest do
  @moduledoc """
  Comprehensive LiveView-level ownership tests for goals.
  Verifies that server-side event handlers reject actions from non-owners.
  """
  use HeadsUpWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HeadsUp.AuthFixtures
  import HeadsUp.GoalsFixtures

  alias HeadsUp.Goals

  describe "goal detail editing - non-owner blocked" do
    setup do
      owner = user_fixture()
      non_owner = user_fixture()

      goal = goal_fixture(%{user_id: owner.id, privacy: :public})

      %{owner: owner, non_owner: non_owner, goal: goal}
    end

    test "non-owner cannot see edit/freeze/delete buttons", %{
      conn: conn,
      non_owner: non_owner,
      goal: goal
    } do
      conn = log_in_user(conn, non_owner)
      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      refute has_element?(lv, "button", "Freeze Goal")
      refute has_element?(lv, "button", "Edit Goal Details")
      refute has_element?(lv, "button", "Delete Goal")
      refute has_element?(lv, "button", "Fail Goal")
    end

    test "non-owner cannot edit goal title via event", %{
      conn: conn,
      non_owner: non_owner,
      goal: goal
    } do
      conn = log_in_user(conn, non_owner)
      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      html = render_click(lv, "update_title", %{"title" => "Hacked Title"})
      assert html =~ "not authorized"

      # Verify title unchanged
      fresh_goal = Goals.get_goal!(goal.id)
      assert fresh_goal.title == goal.title
    end

    test "non-owner cannot edit goal description via event", %{
      conn: conn,
      non_owner: non_owner,
      goal: goal
    } do
      conn = log_in_user(conn, non_owner)
      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      html = render_click(lv, "update_description", %{"description" => "Hacked desc"})
      assert html =~ "not authorized"
    end

    test "non-owner cannot freeze goal via event", %{conn: conn, non_owner: non_owner, goal: goal} do
      conn = log_in_user(conn, non_owner)
      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      html = render_click(lv, "freeze_goal", %{})
      assert html =~ "not authorized"

      fresh_goal = Goals.get_goal!(goal.id)
      assert fresh_goal.status == :active
    end

    test "non-owner cannot delete goal via event", %{conn: conn, non_owner: non_owner, goal: goal} do
      conn = log_in_user(conn, non_owner)
      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      html = render_click(lv, "delete_goal", %{})
      assert html =~ "not authorized"

      fresh_goal = Goals.get_goal!(goal.id)
      refute fresh_goal.deleted_at
    end

    test "non-owner cannot access edit page", %{conn: conn, non_owner: non_owner, goal: goal} do
      conn = log_in_user(conn, non_owner)

      {:ok, _lv, html} =
        live(conn, ~p"/goals/#{goal.id}/edit")
        |> follow_redirect(conn)

      assert html =~ "You can only edit your own goals"
    end
  end

  describe "goal steps - non-owner blocked" do
    setup do
      owner = user_fixture()
      non_owner = user_fixture()
      goal = goal_fixture(%{user_id: owner.id, privacy: :public})

      {:ok, step} =
        Goals.create_goal_step(%{
          title: "Test Step",
          goal_id: goal.id,
          order: 1,
          completed: false
        })

      %{owner: owner, non_owner: non_owner, goal: goal, step: step}
    end

    test "non-owner cannot add step via event", %{conn: conn, non_owner: non_owner, goal: goal} do
      conn = log_in_user(conn, non_owner)
      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      html = render_click(lv, "add_step", %{"title" => "Hacked Step"})
      assert html =~ "not authorized"
    end

    test "non-owner cannot toggle step completion via event", %{
      conn: conn,
      non_owner: non_owner,
      goal: goal,
      step: step
    } do
      conn = log_in_user(conn, non_owner)
      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      html = render_click(lv, "toggle_step", %{"step-id" => to_string(step.id)})
      assert html =~ "not authorized"

      fresh_step = Goals.get_goal_step!(step.id)
      assert fresh_step.completed == false
    end

    test "non-owner cannot delete step via event", %{
      conn: conn,
      non_owner: non_owner,
      goal: goal,
      step: step
    } do
      conn = log_in_user(conn, non_owner)
      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      html = render_click(lv, "delete_step", %{"step-id" => to_string(step.id)})
      assert html =~ "not authorized"

      # Step should still exist
      assert Goals.get_goal_step!(step.id)
    end
  end

  describe "goal posts - non-owner blocked" do
    setup do
      owner = user_fixture()
      non_owner = user_fixture()
      goal = goal_fixture(%{user_id: owner.id, privacy: :public})
      post = goal_post_fixture(%{user_id: owner.id, goal_id: goal.id, content: "Owner's post"})

      %{owner: owner, non_owner: non_owner, goal: goal, post: post}
    end

    test "non-owner cannot create post via event", %{conn: conn, non_owner: non_owner, goal: goal} do
      conn = log_in_user(conn, non_owner)
      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      html =
        render_click(lv, "create_post", %{
          "content" => "Unauthorized post",
          "post_type" => "update",
          "step_id" => ""
        })

      assert html =~ "not authorized"
    end

    test "non-owner cannot edit owner's post via event", %{
      conn: conn,
      non_owner: non_owner,
      goal: goal,
      post: post
    } do
      conn = log_in_user(conn, non_owner)
      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      html = render_click(lv, "edit_post", %{"post-id" => to_string(post.id)})
      assert html =~ "not authorized"
    end

    test "non-owner cannot delete owner's post via event", %{
      conn: conn,
      non_owner: non_owner,
      goal: goal,
      post: post
    } do
      conn = log_in_user(conn, non_owner)
      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      html = render_click(lv, "delete_post", %{"post-id" => to_string(post.id)})
      assert html =~ "not authorized"
    end

    test "non-owner cannot see post edit/delete buttons", %{
      conn: conn,
      non_owner: non_owner,
      goal: goal
    } do
      conn = log_in_user(conn, non_owner)
      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      refute has_element?(lv, "button[title='Edit post']")
      refute has_element?(lv, "button[title='Delete post']")
    end

    test "non-owner cannot see create post form", %{conn: conn, non_owner: non_owner, goal: goal} do
      conn = log_in_user(conn, non_owner)
      {:ok, _lv, html} = live(conn, ~p"/goals/#{goal.id}")

      refute html =~ "Share an Update"
    end
  end

  describe "owner can perform all actions" do
    setup do
      owner = user_fixture()
      goal = goal_fixture(%{user_id: owner.id, privacy: :public})
      %{owner: owner, goal: goal}
    end

    test "owner sees management buttons", %{conn: conn, owner: owner, goal: goal} do
      conn = log_in_user(conn, owner)
      {:ok, lv, _html} = live(conn, ~p"/goals/#{goal.id}")

      assert has_element?(lv, "button", "Freeze Goal")
      assert has_element?(lv, "button", "Edit Goal Details")
      assert has_element?(lv, "button", "Delete Goal")
    end

    test "owner sees create post form", %{conn: conn, owner: owner, goal: goal} do
      conn = log_in_user(conn, owner)
      {:ok, _lv, html} = live(conn, ~p"/goals/#{goal.id}")

      assert html =~ "Share an Update"
    end

    test "owner can access edit page", %{conn: conn, owner: owner, goal: goal} do
      conn = log_in_user(conn, owner)
      {:ok, _lv, html} = live(conn, ~p"/goals/#{goal.id}/edit")

      assert html =~ "Edit Goal"
    end
  end
end
