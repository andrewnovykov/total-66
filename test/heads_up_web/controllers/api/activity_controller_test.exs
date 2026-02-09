defmodule HeadsUpWeb.Api.ActivityControllerTest do
  use HeadsUpWeb.ConnCase, async: true

  alias HeadsUp.{Goals, Group, Repo}

  setup %{conn: conn} do
    user = HeadsUp.AuthFixtures.user_fixture()
    friend = HeadsUp.AuthFixtures.user_fixture()

    # Make them friends
    {:ok, _} = HeadsUp.Accounts.send_friend_request(user.id, friend.id)
    {:ok, _} = HeadsUp.Accounts.accept_friend_request(friend.id, user.id)

    # Create some test data
    group =
      Repo.insert!(%Group{
        name: "Test Category",
        description: "A test category for activity testing",
        image_path: "/test/image.jpg",
        status: :published
      })

    {:ok, goal} =
      Goals.create_goal(%{
        title: "Test Goal",
        description: "A test goal",
        privacy: :public,
        user_id: user.id,
        group_id: group.id,
        target_date: DateTime.add(DateTime.utc_now(), 30, :day)
      })

    conn = put_req_header(conn, "accept", "application/json")

    %{conn: conn, user: user, friend: friend, goal: goal, group: group}
  end

  describe "GET /api/activities/:user_id" do
    test "returns user activities when authenticated", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> get("/api/activities/#{user.id}")

      response = json_response(conn, 200)
      assert response["success"] == true
      assert is_list(response["data"])

      # Should include goal creation activity
      activities = response["data"]
      assert Enum.any?(activities, &(&1["activity_type"] == "goal_created"))
    end

    test "supports pagination", %{conn: conn, user: user, group: group} do
      # Create multiple goals to generate activities
      # Use :completed status to avoid active item limit (max 3)
      for i <- 1..25 do
        {:ok, _goal} =
          HeadsUp.Goals.create_goal(%{
            title: "Goal #{i}",
            description: "Goal description #{i}",
            privacy: :public,
            user_id: user.id,
            group_id: group.id,
            status: :completed,
            target_date: DateTime.add(DateTime.utc_now(), 30, :day)
          })
      end

      # Test first page
      conn1 =
        conn
        |> log_in_user(user)
        |> get("/api/activities/#{user.id}?page=1&limit=10")

      response1 = json_response(conn1, 200)
      assert length(response1["data"]) == 10

      # Test second page
      conn2 =
        conn
        |> log_in_user(user)
        |> get("/api/activities/#{user.id}?page=2&limit=10")

      response2 = json_response(conn2, 200)
      assert length(response2["data"]) == 10

      # Activities should be different
      ids1 = Enum.map(response1["data"], & &1["id"])
      ids2 = Enum.map(response2["data"], & &1["id"])
      assert ids1 != ids2
    end

    test "denies access to private user's activities", %{conn: conn, user: user} do
      other_user = HeadsUp.AuthFixtures.user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get("/api/activities/#{other_user.id}")

      response = json_response(conn, 403)
      assert response["success"] == false
      assert response["error"]["message"] == "Access denied"
    end

    test "allows access to friend's activities", %{conn: conn, user: user, friend: friend} do
      conn =
        conn
        |> log_in_user(user)
        |> get("/api/activities/#{friend.id}")

      response = json_response(conn, 200)
      assert response["success"] == true
      assert is_list(response["data"])
    end

    test "requires authentication", %{conn: conn, user: user} do
      conn = get(conn, "/api/activities/#{user.id}")

      response = json_response(conn, 401)
      assert response["error"]["message"] == "Authentication required"
    end

    test "handles invalid user ID", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> get("/api/activities/invalid")

      response = json_response(conn, 400)
      assert response["error"]["message"] == "Invalid user ID"
    end
  end

  describe "GET /api/feed" do
    test "returns user feed when authenticated", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> get("/api/feed")

      response = json_response(conn, 200)
      assert response["success"] == true
      assert is_list(response["data"])
    end

    test "includes activities from friends", %{
      conn: conn,
      user: user,
      friend: friend,
      group: group
    } do
      # Create a goal by friend
      {:ok, _friend_goal} =
        HeadsUp.Goals.create_goal(%{
          title: "Friend's Goal",
          description: "A goal by friend",
          privacy: :public,
          user_id: friend.id,
          group_id: group.id,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      conn =
        conn
        |> log_in_user(user)
        |> get("/api/feed")

      response = json_response(conn, 200)
      feed_items = response["data"]

      # Should include friend's activity
      assert Enum.any?(feed_items, fn item ->
               item["user"]["id"] == friend.id && item["activity_type"] == "goal_created"
             end)
    end

    test "supports pagination", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> get("/api/feed?page=1&limit=5")

      response = json_response(conn, 200)
      assert length(response["data"]) <= 5
    end

    test "requires authentication", %{conn: conn} do
      conn = get(conn, "/api/feed")

      response = json_response(conn, 401)
      assert response["error"]["message"] == "Authentication required"
    end
  end

  describe "GET /api/chart/:user_id" do
    test "returns chart data for user", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> get("/api/chart/#{user.id}")

      response = json_response(conn, 200)
      assert response["success"] == true
      assert is_list(response["data"])

      # Should have 365 days of data
      assert length(response["data"]) == 365
    end

    test "supports year parameter", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> get("/api/chart/#{user.id}?year=2023")

      response = json_response(conn, 200)
      chart_data = response["data"]

      # Should contain data for 2023
      first_date = List.first(chart_data)["date"]
      last_date = List.last(chart_data)["date"]

      assert String.starts_with?(first_date, "2023")
      assert String.starts_with?(last_date, "2023")
    end

    test "requires authentication", %{conn: conn, user: user} do
      conn = get(conn, "/api/chart/#{user.id}")

      response = json_response(conn, 401)
      assert response["error"]["message"] == "Authentication required"
    end

    test "denies access to private user's chart", %{conn: conn, user: user} do
      other_user = HeadsUp.AuthFixtures.user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get("/api/chart/#{other_user.id}")

      response = json_response(conn, 403)
      assert response["error"]["message"] == "Access denied"
    end
  end

  describe "GET /api/users/:user_id/stats" do
    test "returns user statistics", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> get("/api/users/#{user.id}/stats")

      response = json_response(conn, 200)
      stats = response["data"]

      assert is_integer(stats["level"])
      assert is_binary(stats["level_name"])
      assert is_integer(stats["xp"])
      assert is_integer(stats["total_goals"])
      assert is_integer(stats["completed_goals"])
      assert is_number(stats["completion_rate"])
      assert is_integer(stats["current_streak"])
      assert is_integer(stats["longest_streak"])
    end

    test "calculates completion rate correctly", %{
      conn: conn,
      user: user,
      goal: goal,
      group: group
    } do
      # Complete the existing goal
      {:ok, _} = Goals.update_goal_with_ownership(goal, %{status: :completed}, user.id)

      # Create another completed goal
      {:ok, goal2} =
        Goals.create_goal(%{
          title: "Another Goal",
          description: "Another test goal",
          privacy: :public,
          user_id: user.id,
          group_id: group.id,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      {:ok, _} = Goals.update_goal_with_ownership(goal2, %{status: :completed}, user.id)

      # Create an active goal
      {:ok, _goal3} =
        Goals.create_goal(%{
          title: "Active Goal",
          description: "An active goal",
          privacy: :public,
          user_id: user.id,
          group_id: group.id,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      conn =
        conn
        |> log_in_user(user)
        |> get("/api/users/#{user.id}/stats")

      response = json_response(conn, 200)
      stats = response["data"]

      # Should have 3 total goals, 2 completed (66.7% completion rate)
      assert stats["total_goals"] == 3
      assert stats["completed_goals"] == 2
      assert stats["completion_rate"] == 66.7
    end

    test "requires authentication", %{conn: conn, user: user} do
      conn = get(conn, "/api/users/#{user.id}/stats")

      response = json_response(conn, 401)
      assert response["error"]["message"] == "Authentication required"
    end

    test "allows access to friend's stats", %{conn: conn, user: user, friend: friend} do
      conn =
        conn
        |> log_in_user(user)
        |> get("/api/users/#{friend.id}/stats")

      response = json_response(conn, 200)
      assert response["success"] == true
    end
  end

  describe "Error Handling" do
    test "handles non-existent user gracefully", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> get("/api/activities/99999")

      # Should return 403 (access denied) rather than 404, for privacy
      response = json_response(conn, 403)
      assert response["error"]["message"] == "Access denied"
    end

    test "validates pagination parameters", %{conn: conn, user: user} do
      # Test invalid page
      conn1 =
        conn
        |> log_in_user(user)
        |> get("/api/feed?page=0")

      response1 = json_response(conn1, 200)
      # Should default to page 1
      assert response1["success"] == true

      # Test invalid limit (too high)
      conn2 =
        conn
        |> log_in_user(user)
        |> get("/api/feed?limit=200")

      response2 = json_response(conn2, 200)
      # Should cap at reasonable limit
      assert length(response2["data"]) <= 100
    end
  end
end
