defmodule HeadsUpWeb.Api.ReportControllerTest do
  use HeadsUpWeb.ConnCase, async: false

  alias HeadsUp.{Auth, Reports}
  import HeadsUp.GoalsFixtures
  import HeadsUp.ChallengesFixtures

  setup do
    {:ok, user} =
      Auth.register_user(%{
        name: "Reporter",
        user_name: "reporter_user",
        email: "reporter@test.com",
        password: "password123456"
      })

    {:ok, other_user} =
      Auth.register_user(%{
        name: "Content Owner",
        user_name: "content_owner",
        email: "content_owner@test.com",
        password: "password123456"
      })

    %{user: user, other_user: other_user}
  end

  # ============================================================================
  # POST /api/goals/:id/report
  # ============================================================================

  describe "POST /api/goals/:id/report" do
    test "successfully reports a goal", %{conn: conn, user: user, other_user: other_user} do
      goal = goal_fixture(%{user_id: other_user.id})

      conn =
        conn
        |> log_in_user(user)
        |> post("/api/goals/#{goal.id}/report", %{"reason" => "spam"})

      assert %{"data" => report} = json_response(conn, 201)
      assert report["reason"] == "spam"
      assert report["goal_id"] == goal.id
    end

    test "reports goal with description", %{conn: conn, user: user, other_user: other_user} do
      goal = goal_fixture(%{user_id: other_user.id})

      conn =
        conn
        |> log_in_user(user)
        |> post("/api/goals/#{goal.id}/report", %{
          "reason" => "offensive",
          "description" => "Contains inappropriate content"
        })

      assert %{"data" => report} = json_response(conn, 201)
      assert report["description"] == "Contains inappropriate content"
    end

    test "returns 409 for duplicate report", %{conn: conn, user: user, other_user: other_user} do
      goal = goal_fixture(%{user_id: other_user.id})
      Reports.report_goal(goal.id, user.id, %{reason: "spam"})

      conn =
        conn
        |> log_in_user(user)
        |> post("/api/goals/#{goal.id}/report", %{"reason" => "spam"})

      assert json_response(conn, 409)
    end

    test "returns 403 for own goal", %{conn: conn, user: user} do
      goal = goal_fixture(%{user_id: user.id})

      conn =
        conn
        |> log_in_user(user)
        |> post("/api/goals/#{goal.id}/report", %{"reason" => "spam"})

      assert json_response(conn, 403)
    end

    test "returns 401 for unauthenticated", %{conn: conn, other_user: other_user} do
      goal = goal_fixture(%{user_id: other_user.id})

      conn = post(conn, "/api/goals/#{goal.id}/report", %{"reason" => "spam"})
      assert json_response(conn, 401)
    end

    test "returns 404 for non-existent goal", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> post("/api/goals/999999/report", %{"reason" => "spam"})

      assert json_response(conn, 404)
    end

    test "returns 400 for invalid ID", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> post("/api/goals/abc/report", %{"reason" => "spam"})

      assert json_response(conn, 400)
    end
  end

  # ============================================================================
  # POST /api/posts/:id/report
  # ============================================================================

  describe "POST /api/posts/:id/report" do
    test "successfully reports a post", %{conn: conn, user: user, other_user: other_user} do
      goal = goal_fixture(%{user_id: other_user.id})
      post_record = goal_post_fixture(%{user_id: other_user.id, goal_id: goal.id})

      conn =
        conn
        |> log_in_user(user)
        |> post("/api/posts/#{post_record.id}/report", %{"reason" => "spam"})

      assert %{"data" => report} = json_response(conn, 201)
      assert report["reason"] == "spam"
      assert report["post_id"] == post_record.id
    end

    test "returns 409 for duplicate report", %{conn: conn, user: user, other_user: other_user} do
      goal = goal_fixture(%{user_id: other_user.id})
      post_record = goal_post_fixture(%{user_id: other_user.id, goal_id: goal.id})
      Reports.report_post(post_record.id, user.id, %{reason: "spam"})

      conn =
        conn
        |> log_in_user(user)
        |> post("/api/posts/#{post_record.id}/report", %{"reason" => "spam"})

      assert json_response(conn, 409)
    end

    test "returns 403 for own post", %{conn: conn, user: user} do
      goal = goal_fixture(%{user_id: user.id})
      post_record = goal_post_fixture(%{user_id: user.id, goal_id: goal.id})

      conn =
        conn
        |> log_in_user(user)
        |> post("/api/posts/#{post_record.id}/report", %{"reason" => "spam"})

      assert json_response(conn, 403)
    end

    test "returns 401 for unauthenticated", %{conn: conn, other_user: other_user} do
      goal = goal_fixture(%{user_id: other_user.id})
      post_record = goal_post_fixture(%{user_id: other_user.id, goal_id: goal.id})

      conn = post(conn, "/api/posts/#{post_record.id}/report", %{"reason" => "spam"})
      assert json_response(conn, 401)
    end

    test "returns 404 for non-existent post", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> post("/api/posts/999999/report", %{"reason" => "spam"})

      assert json_response(conn, 404)
    end
  end

  # ============================================================================
  # POST /api/users/:id/report
  # ============================================================================

  describe "POST /api/users/:id/report" do
    test "successfully reports a user", %{conn: conn, user: user, other_user: other_user} do
      conn =
        conn
        |> log_in_user(user)
        |> post("/api/users/#{other_user.id}/report", %{"reason" => "harassment"})

      assert %{"data" => report} = json_response(conn, 201)
      assert report["reason"] == "harassment"
      assert report["reported_user_id"] == other_user.id
    end

    test "returns 409 for duplicate report", %{conn: conn, user: user, other_user: other_user} do
      Reports.report_user(other_user.id, user.id, %{reason: "spam"})

      conn =
        conn
        |> log_in_user(user)
        |> post("/api/users/#{other_user.id}/report", %{"reason" => "spam"})

      assert json_response(conn, 409)
    end

    test "returns 403 for reporting yourself", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> post("/api/users/#{user.id}/report", %{"reason" => "spam"})

      assert json_response(conn, 403)
    end

    test "returns 401 for unauthenticated", %{conn: conn, other_user: other_user} do
      conn = post(conn, "/api/users/#{other_user.id}/report", %{"reason" => "spam"})
      assert json_response(conn, 401)
    end

    test "returns 404 for non-existent user", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> post("/api/users/999999/report", %{"reason" => "spam"})

      assert json_response(conn, 404)
    end

    test "returns 400 for invalid ID", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> post("/api/users/abc/report", %{"reason" => "spam"})

      assert json_response(conn, 400)
    end
  end

  # ============================================================================
  # POST /api/challenges/:id/report
  # ============================================================================

  describe "POST /api/challenges/:id/report" do
    test "successfully reports a challenge", %{conn: conn, user: user, other_user: other_user} do
      challenge = challenge_fixture(%{is_template: true, user: other_user})

      conn =
        conn
        |> log_in_user(user)
        |> post("/api/challenges/#{challenge.id}/report", %{"reason" => "spam"})

      assert %{"data" => report} = json_response(conn, 201)
      assert report["reason"] == "spam"
      assert report["challenge_id"] == challenge.id
    end

    test "returns 409 for duplicate report", %{conn: conn, user: user, other_user: other_user} do
      challenge = challenge_fixture(%{is_template: true, user: other_user})
      Reports.report_challenge(challenge.id, user.id, %{reason: "spam"})

      conn =
        conn
        |> log_in_user(user)
        |> post("/api/challenges/#{challenge.id}/report", %{"reason" => "spam"})

      assert json_response(conn, 409)
    end

    test "returns 403 for own challenge", %{conn: conn, user: user} do
      challenge = challenge_fixture(%{is_template: true, user: user})

      conn =
        conn
        |> log_in_user(user)
        |> post("/api/challenges/#{challenge.id}/report", %{"reason" => "spam"})

      assert json_response(conn, 403)
    end

    test "returns 401 for unauthenticated", %{conn: conn, other_user: other_user} do
      challenge = challenge_fixture(%{is_template: true, user: other_user})

      conn = post(conn, "/api/challenges/#{challenge.id}/report", %{"reason" => "spam"})
      assert json_response(conn, 401)
    end

    test "returns 404 for non-existent challenge", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> post("/api/challenges/999999/report", %{"reason" => "spam"})

      assert json_response(conn, 404)
    end

    test "returns 400 for invalid ID", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> post("/api/challenges/abc/report", %{"reason" => "spam"})

      assert json_response(conn, 400)
    end
  end
end
