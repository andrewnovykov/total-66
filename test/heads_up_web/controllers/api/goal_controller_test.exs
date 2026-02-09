defmodule HeadsUpWeb.Api.GoalControllerTest do
  use HeadsUpWeb.ConnCase, async: false

  alias HeadsUp.{Goals, Auth, Group, Repo}

  setup do
    # Create test users
    {:ok, user1} =
      Auth.register_user(%{
        name: "Test User 1",
        user_name: "test_user_1",
        email: "test1@example.com",
        password: "password123456"
      })

    {:ok, user2} =
      Auth.register_user(%{
        name: "Test User 2",
        user_name: "test_user_2",
        email: "test2@example.com",
        password: "password123456"
      })

    # Create a test group/category
    group =
      Repo.insert!(%Group{
        name: "Test Category",
        description: "A test category for API testing",
        image_path: "/test/image.jpg",
        status: :published
      })

    # Create test goals
    {:ok, public_goal_user1} =
      Goals.create_goal(%{
        title: "User 1 Public Goal",
        description: "A public goal by user 1",
        privacy: :public,
        user_id: user1.id,
        group_id: group.id,
        target_date: DateTime.add(DateTime.utc_now(), 30, :day)
      })

    {:ok, private_goal_user1} =
      Goals.create_goal(%{
        title: "User 1 Private Goal",
        description: "A private goal by user 1",
        privacy: :private,
        user_id: user1.id,
        group_id: group.id,
        target_date: DateTime.add(DateTime.utc_now(), 30, :day)
      })

    {:ok, public_goal_user2} =
      Goals.create_goal(%{
        title: "User 2 Public Goal",
        description: "A public goal by user 2",
        privacy: :public,
        user_id: user2.id,
        group_id: group.id,
        target_date: DateTime.add(DateTime.utc_now(), 30, :day)
      })

    %{
      user1: user1,
      user2: user2,
      group: group,
      public_goal_user1: public_goal_user1,
      private_goal_user1: private_goal_user1,
      public_goal_user2: public_goal_user2
    }
  end

  describe "authentication and authorization" do
    test "unauthenticated users cannot access protected endpoints", %{public_goal_user1: goal} do
      # Test /my endpoint
      conn = get(build_conn(), "/api/goals/my")
      assert json_response(conn, 401)["error"]["message"] == "Authentication required"

      # Test create goal
      conn = post(build_conn(), "/api/goals", %{goal: %{title: "Test"}})
      assert json_response(conn, 401)["error"]["message"] == "Authentication required"

      # Test update goal
      conn = put(build_conn(), "/api/goals/#{goal.id}", %{goal: %{title: "Updated"}})
      assert json_response(conn, 401)["error"]["message"] == "Authentication required"

      # Test delete goal
      conn = delete(build_conn(), "/api/goals/#{goal.id}")
      assert json_response(conn, 401)["error"]["message"] == "Authentication required"

      # Test like goal
      conn = post(build_conn(), "/api/goals/#{goal.id}/like")
      assert json_response(conn, 401)["error"]["message"] == "Authentication required"

      # Test subscribe to goal
      conn = post(build_conn(), "/api/goals/#{goal.id}/subscribe")
      assert json_response(conn, 401)["error"]["message"] == "Authentication required"
    end

    test "users cannot edit other users' goals", %{user2: user2, public_goal_user1: goal} do
      conn =
        build_conn()
        |> log_in_user(user2)
        |> put("/api/goals/#{goal.id}", %{goal: %{title: "Hacked Title"}})

      assert json_response(conn, 403)["error"]["message"] == "You can only update your own goals"
    end

    test "users cannot delete other users' goals", %{user2: user2, public_goal_user1: goal} do
      conn =
        build_conn()
        |> log_in_user(user2)
        |> delete("/api/goals/#{goal.id}")

      assert json_response(conn, 403)["error"]["message"] == "You can only delete your own goals"
    end

    test "users cannot access other users' private goals", %{
      user2: user2,
      private_goal_user1: private_goal
    } do
      conn =
        build_conn()
        |> log_in_user(user2)
        |> get("/api/goals/#{private_goal.id}")

      assert json_response(conn, 403)["error"]["message"] == "Access denied"
    end

    test "unauthenticated users cannot access private goals", %{private_goal_user1: private_goal} do
      conn = get(build_conn(), "/api/goals/#{private_goal.id}")
      assert json_response(conn, 403)["error"]["message"] == "Access denied"
    end

    test "goal owners can access their own private goals", %{
      user1: user1,
      private_goal_user1: private_goal
    } do
      conn =
        build_conn()
        |> log_in_user(user1)
        |> get("/api/goals/#{private_goal.id}")

      assert json_response(conn, 200)["data"]["id"] == private_goal.id
      assert json_response(conn, 200)["data"]["privacy"] == "private"
    end

    test "users can like other users' public goals but not their own", %{
      user1: user1,
      user2: user2,
      public_goal_user1: goal1,
      public_goal_user2: goal2
    } do
      # User 2 can like User 1's goal
      conn =
        build_conn()
        |> log_in_user(user2)
        |> post("/api/goals/#{goal1.id}/like")

      assert json_response(conn, 200)["message"] == "Goal liked successfully"

      # User 1 cannot like their own goal
      conn =
        build_conn()
        |> log_in_user(user1)
        |> post("/api/goals/#{goal1.id}/like")

      assert json_response(conn, 403)["error"]["message"] == "You cannot like your own goal"
    end

    test "users can subscribe to other users' public goals but not their own", %{
      user1: user1,
      user2: user2,
      public_goal_user1: goal1,
      public_goal_user2: goal2
    } do
      # User 2 can subscribe to User 1's goal
      conn =
        build_conn()
        |> log_in_user(user2)
        |> post("/api/goals/#{goal1.id}/subscribe")

      assert json_response(conn, 200)["message"] == "Subscribed to goal successfully"

      # User 1 cannot subscribe to their own goal
      conn =
        build_conn()
        |> log_in_user(user1)
        |> post("/api/goals/#{goal1.id}/subscribe")

      assert json_response(conn, 403)["error"]["message"] ==
               "You cannot subscribe to your own goal"
    end

    test "users can update and delete their own goals", %{user1: user1, public_goal_user1: goal} do
      # Test update
      conn =
        build_conn()
        |> log_in_user(user1)
        |> put("/api/goals/#{goal.id}", %{goal: %{title: "Updated Title"}})

      assert json_response(conn, 200)["data"]["title"] == "Updated Title"

      # Test delete
      conn =
        build_conn()
        |> log_in_user(user1)
        |> delete("/api/goals/#{goal.id}")

      assert json_response(conn, 200)["message"] == "Goal deleted successfully"
    end

    test "users can access their own goals via /my endpoint", %{user1: user1} do
      conn =
        build_conn()
        |> log_in_user(user1)
        |> get("/api/goals/my")

      response = json_response(conn, 200)
      assert is_list(response["data"])

      # All goals should belong to user1
      Enum.each(response["data"], fn goal ->
        assert goal["creator"]["id"] == user1.id
      end)
    end

    test "public goal listing only shows public goals", %{
      public_goal_user1: public_goal,
      private_goal_user1: private_goal
    } do
      conn = get(build_conn(), "/api/goals")
      response = json_response(conn, 200)

      goal_ids = Enum.map(response["data"], & &1["id"])
      assert public_goal.id in goal_ids
      refute private_goal.id in goal_ids

      # All returned goals should be public
      Enum.each(response["data"], fn goal ->
        assert goal["privacy"] == "public"
      end)
    end

    test "users can unlike and unsubscribe from goals they previously liked/subscribed", %{
      user1: user1,
      user2: user2,
      public_goal_user2: goal
    } do
      # First, like and subscribe
      conn1 = build_conn() |> log_in_user(user1)

      post(conn1, "/api/goals/#{goal.id}/like")
      post(conn1, "/api/goals/#{goal.id}/subscribe")

      # Then unlike and unsubscribe
      conn =
        conn1
        |> delete("/api/goals/#{goal.id}/like")

      assert json_response(conn, 200)["message"] == "Goal unliked successfully"

      conn =
        conn1
        |> delete("/api/goals/#{goal.id}/subscribe")

      assert json_response(conn, 200)["message"] == "Unsubscribed from goal successfully"
    end
  end

  describe "edge cases and validation" do
    test "accessing non-existent goal returns 404", %{user1: user1} do
      conn =
        build_conn()
        |> log_in_user(user1)
        |> get("/api/goals/99999")

      assert json_response(conn, 404)["error"]["message"] == "Goal not found"
    end

    test "invalid goal ID format returns 400" do
      conn = get(build_conn(), "/api/goals/invalid-id")
      assert json_response(conn, 400)["error"]["message"] == "Invalid goal ID"
    end

    test "accessing invalid category returns 404" do
      conn = get(build_conn(), "/api/goals/category/99999")
      assert json_response(conn, 404)["error"]["message"] == "Category not found"
    end
  end
end
