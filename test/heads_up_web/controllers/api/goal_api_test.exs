defmodule HeadsUpWeb.Api.GoalAPITest do
  use HeadsUpWeb.ConnCase

  alias HeadsUp.{Goals, Group, Repo}

  setup %{conn: conn} do
    # Create two test users
    user1 = HeadsUp.AuthFixtures.user_fixture()
    user2 = HeadsUp.AuthFixtures.user_fixture()

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
      conn: conn,
      user1: user1,
      user2: user2,
      group: group,
      public_goal_user1: public_goal_user1,
      private_goal_user1: private_goal_user1,
      public_goal_user2: public_goal_user2
    }
  end

  describe "API Authentication" do
    test "unauthenticated users cannot access protected endpoints", %{
      conn: conn,
      public_goal_user1: goal
    } do
      # Test /my endpoint
      conn = get(conn, "/api/goals/my")
      assert json_response(conn, 401)["error"]["message"] == "Authentication required"

      # Test create goal
      conn = post(conn, "/api/goals", %{goal: %{title: "Test"}})
      assert json_response(conn, 401)["error"]["message"] == "Authentication required"

      # Test update goal
      conn = put(conn, "/api/goals/#{goal.id}", %{goal: %{title: "Updated"}})
      assert json_response(conn, 401)["error"]["message"] == "Authentication required"

      # Test delete goal
      conn = delete(conn, "/api/goals/#{goal.id}")
      assert json_response(conn, 401)["error"]["message"] == "Authentication required"

      # Test like goal
      conn = post(conn, "/api/goals/#{goal.id}/like")
      assert json_response(conn, 401)["error"]["message"] == "Authentication required"

      # Test subscribe to goal
      conn = post(conn, "/api/goals/#{goal.id}/subscribe")
      assert json_response(conn, 401)["error"]["message"] == "Authentication required"
    end
  end

  describe "Goal Ownership Controls" do
    test "users cannot edit other users' goals", %{
      conn: conn,
      user2: user2,
      public_goal_user1: goal
    } do
      conn =
        conn
        |> log_in_user(user2)
        |> put("/api/goals/#{goal.id}", %{goal: %{title: "Hacked Title"}})

      assert json_response(conn, 403)["error"]["message"] == "You can only update your own goals"
    end

    test "users cannot delete other users' goals", %{
      conn: conn,
      user2: user2,
      public_goal_user1: goal
    } do
      conn =
        conn
        |> log_in_user(user2)
        |> delete("/api/goals/#{goal.id}")

      assert json_response(conn, 403)["error"]["message"] == "You can only delete your own goals"
    end

    test "users can update their own goals", %{conn: conn, user1: user1, public_goal_user1: goal} do
      conn =
        conn
        |> log_in_user(user1)
        |> put("/api/goals/#{goal.id}", %{goal: %{title: "Updated Title"}})

      assert json_response(conn, 200)["data"]["title"] == "Updated Title"
    end

    test "users can delete their own goals", %{conn: conn, user1: user1, public_goal_user1: goal} do
      conn =
        conn
        |> log_in_user(user1)
        |> delete("/api/goals/#{goal.id}")

      assert json_response(conn, 200)["message"] == "Goal deleted successfully"
    end
  end

  describe "Privacy Controls" do
    test "users cannot access other users' private goals", %{
      conn: conn,
      user2: user2,
      private_goal_user1: private_goal
    } do
      conn =
        conn
        |> log_in_user(user2)
        |> get("/api/goals/#{private_goal.id}")

      assert json_response(conn, 403)["error"]["message"] == "Access denied"
    end

    test "unauthenticated users cannot access private goals", %{
      conn: conn,
      private_goal_user1: private_goal
    } do
      conn = get(conn, "/api/goals/#{private_goal.id}")
      assert json_response(conn, 403)["error"]["message"] == "Access denied"
    end

    test "goal owners can access their own private goals", %{
      conn: conn,
      user1: user1,
      private_goal_user1: private_goal
    } do
      conn =
        conn
        |> log_in_user(user1)
        |> get("/api/goals/#{private_goal.id}")

      response = json_response(conn, 200)
      assert response["data"]["id"] == private_goal.id
      assert response["data"]["privacy"] == "private"
    end

    test "public goal listing only shows public goals", %{
      conn: conn,
      public_goal_user1: public_goal,
      private_goal_user1: private_goal
    } do
      conn = get(conn, "/api/goals")
      response = json_response(conn, 200)

      goal_ids = Enum.map(response["data"], & &1["id"])
      assert public_goal.id in goal_ids
      refute private_goal.id in goal_ids

      # All returned goals should be public
      Enum.each(response["data"], fn goal ->
        assert goal["privacy"] == "public"
      end)
    end
  end

  describe "Social Interaction Controls" do
    test "users can like other users' public goals but not their own", %{
      conn: conn,
      user1: user1,
      user2: user2,
      public_goal_user1: goal1
    } do
      # User 2 can like User 1's goal
      conn2 =
        conn
        |> log_in_user(user2)
        |> post("/api/goals/#{goal1.id}/like")

      assert json_response(conn2, 200)["message"] == "Goal liked successfully"

      # User 1 cannot like their own goal
      conn1 =
        conn
        |> log_in_user(user1)
        |> post("/api/goals/#{goal1.id}/like")

      assert json_response(conn1, 403)["error"]["message"] == "You cannot like your own goal"
    end

    test "users can subscribe to other users' public goals but not their own", %{
      conn: conn,
      user1: user1,
      user2: user2,
      public_goal_user1: goal1
    } do
      # User 2 can subscribe to User 1's goal
      conn2 =
        conn
        |> log_in_user(user2)
        |> post("/api/goals/#{goal1.id}/subscribe")

      assert json_response(conn2, 200)["message"] == "Subscribed to goal successfully"

      # User 1 cannot subscribe to their own goal
      conn1 =
        conn
        |> log_in_user(user1)
        |> post("/api/goals/#{goal1.id}/subscribe")

      assert json_response(conn1, 403)["error"]["message"] ==
               "You cannot subscribe to your own goal"
    end

    test "users can unlike and unsubscribe from goals", %{
      conn: conn,
      user1: user1,
      public_goal_user2: goal
    } do
      # First, like and subscribe
      auth_conn = log_in_user(conn, user1)

      post(auth_conn, "/api/goals/#{goal.id}/like")
      post(auth_conn, "/api/goals/#{goal.id}/subscribe")

      # Then unlike and unsubscribe
      conn = delete(auth_conn, "/api/goals/#{goal.id}/like")
      assert json_response(conn, 200)["message"] == "Goal unliked successfully"

      conn = delete(auth_conn, "/api/goals/#{goal.id}/subscribe")
      assert json_response(conn, 200)["message"] == "Unsubscribed from goal successfully"
    end

    test "users can like private goals but cannot subscribe to them", %{
      conn: conn,
      user2: user2,
      private_goal_user1: private_goal
    } do
      # Users CAN like private goals (according to project spec)
      conn_like =
        conn
        |> log_in_user(user2)
        |> post("/api/goals/#{private_goal.id}/like")

      assert json_response(conn_like, 200)["message"] == "Goal liked successfully"

      # But users CANNOT subscribe to private goals
      conn_subscribe =
        conn
        |> log_in_user(user2)
        |> post("/api/goals/#{private_goal.id}/subscribe")

      # This should fail because the goal is private and they're not the owner
      assert json_response(conn_subscribe, 403)["error"]["message"] == "Access denied"
    end

    test "self-interaction prevention - comprehensive test", %{
      conn: conn,
      user1: user1,
      public_goal_user1: own_goal
    } do
      auth_conn = log_in_user(conn, user1)

      # User cannot like their own goal
      conn_like = post(auth_conn, "/api/goals/#{own_goal.id}/like")
      assert json_response(conn_like, 403)["error"]["message"] == "You cannot like your own goal"

      # User cannot subscribe to their own goal  
      conn_sub = post(auth_conn, "/api/goals/#{own_goal.id}/subscribe")

      assert json_response(conn_sub, 403)["error"]["message"] ==
               "You cannot subscribe to your own goal"

      # User cannot unlike their own goal (should fail because they never liked it)
      conn_unlike = delete(auth_conn, "/api/goals/#{own_goal.id}/like")
      assert json_response(conn_unlike, 422)["error"]["message"] == "Failed to unlike goal"

      # User cannot unsubscribe from their own goal (should fail because they never subscribed)
      conn_unsub = delete(auth_conn, "/api/goals/#{own_goal.id}/subscribe")

      assert json_response(conn_unsub, 422)["error"]["message"] ==
               "Failed to unsubscribe from goal"
    end
  end

  describe "Goal Ownership CRUD Operations" do
    test "users can edit their own goals", %{
      conn: conn,
      user1: user1,
      public_goal_user1: own_goal
    } do
      updated_attrs = %{
        title: "Updated Goal Title",
        description: "Updated goal description",
        privacy: "private"
      }

      conn =
        conn
        |> log_in_user(user1)
        |> put("/api/goals/#{own_goal.id}", %{goal: updated_attrs})

      response = json_response(conn, 200)
      assert response["data"]["title"] == "Updated Goal Title"
      assert response["data"]["description"] == "Updated goal description"
      assert response["data"]["privacy"] == "private"
    end

    test "users cannot edit other users' goals", %{
      conn: conn,
      user2: user2,
      public_goal_user1: other_goal
    } do
      updated_attrs = %{
        title: "Hacked Title",
        description: "This should not work"
      }

      conn =
        conn
        |> log_in_user(user2)
        |> put("/api/goals/#{other_goal.id}", %{goal: updated_attrs})

      assert json_response(conn, 403)["error"]["message"] == "You can only update your own goals"
    end

    test "users can soft delete their own goals", %{
      conn: conn,
      user1: user1,
      public_goal_user1: own_goal
    } do
      conn =
        conn
        |> log_in_user(user1)
        |> delete("/api/goals/#{own_goal.id}")

      assert json_response(conn, 200)["message"] == "Goal deleted successfully"

      # Verify goal is soft deleted by checking it's not in public listings
      conn = get(conn, "/api/goals")
      response = json_response(conn, 200)
      goal_ids = Enum.map(response["data"], & &1["id"])
      refute own_goal.id in goal_ids
    end

    test "users cannot delete other users' goals", %{
      conn: conn,
      user2: user2,
      public_goal_user1: other_goal
    } do
      conn =
        conn
        |> log_in_user(user2)
        |> delete("/api/goals/#{other_goal.id}")

      assert json_response(conn, 403)["error"]["message"] == "You can only delete your own goals"
    end

    test "deleted goals are not visible in public listings", %{
      conn: conn,
      user1: user1,
      public_goal_user1: own_goal
    } do
      # First verify goal is in public listing
      conn_before = get(conn, "/api/goals")
      response_before = json_response(conn_before, 200)
      goal_ids_before = Enum.map(response_before["data"], & &1["id"])
      assert own_goal.id in goal_ids_before

      # Delete the goal
      conn
      |> log_in_user(user1)
      |> delete("/api/goals/#{own_goal.id}")

      # Verify goal is no longer in public listing
      conn_after = get(conn, "/api/goals")
      response_after = json_response(conn_after, 200)
      goal_ids_after = Enum.map(response_after["data"], & &1["id"])
      refute own_goal.id in goal_ids_after
    end

    test "deleted goals are not accessible via direct API calls", %{
      conn: conn,
      user1: user1,
      user2: user2,
      public_goal_user1: own_goal
    } do
      # Delete the goal
      conn
      |> log_in_user(user1)
      |> delete("/api/goals/#{own_goal.id}")

      # Try to access deleted goal - should return 404
      conn_owner =
        conn
        |> log_in_user(user1)
        |> get("/api/goals/#{own_goal.id}")

      assert json_response(conn_owner, 404)["error"]["message"] == "Goal not found"

      # Other users also can't access deleted goal
      conn_other =
        conn
        |> log_in_user(user2)
        |> get("/api/goals/#{own_goal.id}")

      assert json_response(conn_other, 404)["error"]["message"] == "Goal not found"
    end
  end

  describe "Goal Deletion and Restoration" do
    test "users can restore their own deleted goals", %{
      conn: conn,
      user1: user1,
      public_goal_user1: own_goal
    } do
      # First delete the goal
      conn
      |> log_in_user(user1)
      |> delete("/api/goals/#{own_goal.id}")

      # Verify goal is deleted (not in public listings)
      conn_check = get(conn, "/api/goals")
      response_check = json_response(conn_check, 200)
      goal_ids_check = Enum.map(response_check["data"], & &1["id"])
      refute own_goal.id in goal_ids_check

      # Restore the goal
      conn_restore =
        conn
        |> log_in_user(user1)
        |> post("/api/goals/#{own_goal.id}/restore")

      response = json_response(conn_restore, 200)
      assert response["data"]["id"] == own_goal.id
      assert response["data"]["status"] == "active"

      # Verify goal is back in public listings
      conn_after = get(conn, "/api/goals")
      response_after = json_response(conn_after, 200)
      goal_ids_after = Enum.map(response_after["data"], & &1["id"])
      assert own_goal.id in goal_ids_after
    end

    test "users cannot restore other users' deleted goals", %{
      conn: conn,
      user1: user1,
      user2: user2,
      public_goal_user1: other_goal
    } do
      # User 1 deletes their goal
      conn
      |> log_in_user(user1)
      |> delete("/api/goals/#{other_goal.id}")

      # User 2 tries to restore User 1's goal
      conn_restore =
        conn
        |> log_in_user(user2)
        |> post("/api/goals/#{other_goal.id}/restore")

      assert json_response(conn_restore, 403)["error"]["message"] ==
               "You can only restore your own goals"
    end

    test "users can list their deleted goals", %{
      conn: conn,
      user1: user1,
      public_goal_user1: own_goal
    } do
      # Delete the goal
      conn
      |> log_in_user(user1)
      |> delete("/api/goals/#{own_goal.id}")

      # List deleted goals
      conn_deleted =
        conn
        |> log_in_user(user1)
        |> get("/api/goals/deleted")

      response = json_response(conn_deleted, 200)
      assert is_list(response["data"])

      deleted_goal_ids = Enum.map(response["data"], & &1["id"])
      assert own_goal.id in deleted_goal_ids

      # Verify all returned goals have deleted status
      Enum.each(response["data"], fn goal ->
        assert goal["status"] == "deleted"
      end)
    end

    test "restoring non-existent goal returns 404", %{conn: conn, user1: user1} do
      conn_restore =
        conn
        |> log_in_user(user1)
        |> post("/api/goals/99999/restore")

      assert json_response(conn_restore, 404)["error"]["message"] == "Goal not found"
    end

    test "restoring already active goal succeeds (idempotent operation)", %{
      conn: conn,
      user1: user1,
      public_goal_user1: active_goal
    } do
      # Try to restore an already active goal - this should succeed (idempotent)
      conn_restore =
        conn
        |> log_in_user(user1)
        |> post("/api/goals/#{active_goal.id}/restore")

      # This should succeed because restore is an idempotent operation
      response = json_response(conn_restore, 200)
      assert response["data"]["id"] == active_goal.id
      assert response["data"]["status"] == "active"
    end
  end

  describe "Failed Goal Restrictions" do
    test "failed goals cannot be updated", %{
      conn: conn,
      user1: user1,
      public_goal_user1: own_goal
    } do
      # First fail the goal
      conn
      |> log_in_user(user1)
      |> post("/api/goals/#{own_goal.id}/fail", %{reason: "Testing restriction"})

      # Try to update the failed goal
      conn_update =
        conn
        |> log_in_user(user1)
        |> put("/api/goals/#{own_goal.id}", %{goal: %{title: "Updated Title"}})

      assert json_response(conn_update, 403)["error"]["message"] ==
               "Failed goals can only be deleted"
    end

    test "failed goals cannot be frozen", %{conn: conn, user1: user1, public_goal_user1: own_goal} do
      # First fail the goal
      conn
      |> log_in_user(user1)
      |> post("/api/goals/#{own_goal.id}/fail", %{reason: "Testing freeze restriction"})

      # Try to freeze the failed goal
      conn_freeze =
        conn
        |> log_in_user(user1)
        |> post("/api/goals/#{own_goal.id}/freeze")

      assert json_response(conn_freeze, 403)["error"]["message"] ==
               "Failed goals cannot be frozen"
    end

    test "users cannot create posts on failed goals", %{
      conn: conn,
      user1: user1,
      public_goal_user1: own_goal
    } do
      # First fail the goal
      conn
      |> log_in_user(user1)
      |> post("/api/goals/#{own_goal.id}/fail", %{reason: "Testing post restriction"})

      # Test using the Goals module directly since the API endpoint doesn't exist yet
      result =
        HeadsUp.Goals.create_goal_post_with_ownership(
          %{
            "goal_id" => own_goal.id,
            "user_id" => user1.id,
            "content" => "This should not work on failed goal",
            "post_type" => "update"
          },
          user1.id
        )

      assert {:error, :failed} = result
    end

    test "failed goals can still be deleted", %{
      conn: conn,
      user1: user1,
      public_goal_user1: own_goal
    } do
      # First fail the goal
      conn
      |> log_in_user(user1)
      |> post("/api/goals/#{own_goal.id}/fail", %{reason: "Testing deletion"})

      # Delete the failed goal - this should work
      conn_delete =
        conn
        |> log_in_user(user1)
        |> delete("/api/goals/#{own_goal.id}")

      assert json_response(conn_delete, 200)["message"] == "Goal deleted successfully"
    end

    test "failed goals cannot be edited via any means", %{
      conn: conn,
      user1: user1,
      public_goal_user1: own_goal
    } do
      # First fail the goal
      conn
      |> log_in_user(user1)
      |> post("/api/goals/#{own_goal.id}/fail", %{reason: "Comprehensive test"})

      # Try to update title
      conn_title =
        conn
        |> log_in_user(user1)
        |> put("/api/goals/#{own_goal.id}", %{goal: %{title: "New Title"}})

      assert json_response(conn_title, 403)["error"]["message"] ==
               "Failed goals can only be deleted"

      # Try to update description
      conn_desc =
        conn
        |> log_in_user(user1)
        |> put("/api/goals/#{own_goal.id}", %{goal: %{description: "New Description"}})

      assert json_response(conn_desc, 403)["error"]["message"] ==
               "Failed goals can only be deleted"

      # Try to change privacy
      conn_privacy =
        conn
        |> log_in_user(user1)
        |> put("/api/goals/#{own_goal.id}", %{goal: %{privacy: "private"}})

      assert json_response(conn_privacy, 403)["error"]["message"] ==
               "Failed goals can only be deleted"
    end

    test "failed goals remain in listings with failed status", %{
      conn: conn,
      user1: user1,
      public_goal_user1: own_goal
    } do
      # Fail the goal
      failure_reason = "Testing visibility"

      conn
      |> log_in_user(user1)
      |> post("/api/goals/#{own_goal.id}/fail", %{reason: failure_reason})

      # Check public listings
      conn_public = get(conn, "/api/goals")
      response_public = json_response(conn_public, 200)

      # Find the failed goal
      failed_goal = Enum.find(response_public["data"], &(&1["id"] == own_goal.id))
      assert failed_goal
      assert failed_goal["status"] == "failed"
      assert failed_goal["failure_reason"] == failure_reason

      # Check user's own goals listing
      conn_my =
        conn
        |> log_in_user(user1)
        |> get("/api/goals/my")

      response_my = json_response(conn_my, 200)
      my_failed_goal = Enum.find(response_my["data"], &(&1["id"] == own_goal.id))
      assert my_failed_goal
      assert my_failed_goal["status"] == "failed"
    end

    test "comprehensive failed goal restrictions test", %{
      conn: conn,
      user1: user1,
      public_goal_user1: own_goal
    } do
      # Fail the goal with a reason
      failure_reason = "Comprehensive test of all restrictions"

      conn
      |> log_in_user(user1)
      |> post("/api/goals/#{own_goal.id}/fail", %{reason: failure_reason})

      # Verify goal is failed
      conn_check = get(conn, "/api/goals/#{own_goal.id}")
      goal_data = json_response(conn_check, 200)["data"]
      assert goal_data["status"] == "failed"
      assert goal_data["failure_reason"] == failure_reason

      # Test all operations that should fail

      # 1. Cannot update
      conn_update =
        conn
        |> log_in_user(user1)
        |> put("/api/goals/#{own_goal.id}", %{goal: %{title: "Should fail"}})

      assert json_response(conn_update, 403)["error"]["message"] ==
               "Failed goals can only be deleted"

      # 2. Cannot freeze
      conn_freeze =
        conn
        |> log_in_user(user1)
        |> post("/api/goals/#{own_goal.id}/freeze")

      assert json_response(conn_freeze, 403)["error"]["message"] ==
               "Failed goals cannot be frozen"

      # 3. Cannot restore (already tested in another test)
      conn_restore =
        conn
        |> log_in_user(user1)
        |> post("/api/goals/#{own_goal.id}/restore")

      assert json_response(conn_restore, 403)["error"]["message"] ==
               "Failed goals can only be deleted"

      # 4. Cannot create posts (test via Goals module)
      post_result =
        HeadsUp.Goals.create_goal_post_with_ownership(
          %{
            "goal_id" => own_goal.id,
            "user_id" => user1.id,
            "content" => "Should not work",
            "post_type" => "update"
          },
          user1.id
        )

      assert {:error, :failed} = post_result

      # 5. CAN delete - this is the only allowed operation
      conn_delete =
        conn
        |> log_in_user(user1)
        |> delete("/api/goals/#{own_goal.id}")

      assert json_response(conn_delete, 200)["message"] == "Goal deleted successfully"

      # Verify deletion worked
      conn_verify = get(conn, "/api/goals/#{own_goal.id}")
      assert json_response(conn_verify, 404)["error"]["message"] == "Goal not found"
    end
  end

  describe "Goal Failure Functionality" do
    test "users can fail their own goals with a reason", %{
      conn: conn,
      user1: user1,
      public_goal_user1: own_goal
    } do
      failure_reason =
        "I couldn't maintain consistency with my training schedule due to work commitments"

      conn_fail =
        conn
        |> log_in_user(user1)
        |> post("/api/goals/#{own_goal.id}/fail", %{reason: failure_reason})

      response = json_response(conn_fail, 200)
      assert response["data"]["id"] == own_goal.id
      assert response["data"]["status"] == "failed"
      assert response["data"]["failure_reason"] == failure_reason
      assert response["data"]["failed_at"] != nil

      # Verify goal has a failure post created automatically
      assert length(response["data"]["recent_posts"]) > 0
      failure_post = List.first(response["data"]["recent_posts"])
      assert failure_post["content"] == failure_reason
      assert failure_post["post_type"] == "challenge"
    end

    test "users cannot fail other users' goals", %{
      conn: conn,
      user1: user1,
      user2: user2,
      public_goal_user1: other_goal
    } do
      failure_reason = "This should not be allowed"

      conn_fail =
        conn
        |> log_in_user(user2)
        |> post("/api/goals/#{other_goal.id}/fail", %{reason: failure_reason})

      assert json_response(conn_fail, 403)["error"]["message"] ==
               "You can only fail your own goals"
    end

    test "failing a goal requires a reason", %{
      conn: conn,
      user1: user1,
      public_goal_user1: own_goal
    } do
      # Test with empty reason
      conn_empty =
        conn
        |> log_in_user(user1)
        |> post("/api/goals/#{own_goal.id}/fail", %{reason: ""})

      assert json_response(conn_empty, 400)["error"]["message"] == "Failure reason is required"

      # Test with missing reason
      conn_missing =
        conn
        |> log_in_user(user1)
        |> post("/api/goals/#{own_goal.id}/fail", %{})

      assert json_response(conn_missing, 400)["error"]["message"] == "Failure reason is required"
    end

    test "failed goals cannot be restored", %{
      conn: conn,
      user1: user1,
      public_goal_user1: own_goal
    } do
      # First fail the goal
      failure_reason = "Testing restriction"

      conn
      |> log_in_user(user1)
      |> post("/api/goals/#{own_goal.id}/fail", %{reason: failure_reason})

      # Try to restore the failed goal
      conn_restore =
        conn
        |> log_in_user(user1)
        |> post("/api/goals/#{own_goal.id}/restore")

      assert json_response(conn_restore, 403)["error"]["message"] ==
               "Failed goals can only be deleted"
    end

    test "failed goals are visible in listings with proper status", %{
      conn: conn,
      user1: user1,
      public_goal_user1: own_goal
    } do
      # First fail the goal
      failure_reason = "Visible failure test"

      conn
      |> log_in_user(user1)
      |> post("/api/goals/#{own_goal.id}/fail", %{reason: failure_reason})

      # Check public listings still show failed goals
      conn_public = get(conn, "/api/goals")
      response_public = json_response(conn_public, 200)
      goal_ids = Enum.map(response_public["data"], & &1["id"])
      assert own_goal.id in goal_ids

      # Find the failed goal in the response
      failed_goal = Enum.find(response_public["data"], &(&1["id"] == own_goal.id))
      assert failed_goal["status"] == "failed"
      assert failed_goal["failure_reason"] == failure_reason

      # Check user's own goals listing
      conn_my =
        conn
        |> log_in_user(user1)
        |> get("/api/goals/my")

      response_my = json_response(conn_my, 200)
      my_goal_ids = Enum.map(response_my["data"], & &1["id"])
      assert own_goal.id in my_goal_ids
    end

    test "failing non-existent goal returns 404", %{conn: conn, user1: user1} do
      conn_fail =
        conn
        |> log_in_user(user1)
        |> post("/api/goals/99999/fail", %{reason: "This won't work"})

      assert json_response(conn_fail, 404)["error"]["message"] == "Goal not found"
    end

    test "failing deleted goal returns 404", %{
      conn: conn,
      user1: user1,
      public_goal_user1: own_goal
    } do
      # First delete the goal
      conn
      |> log_in_user(user1)
      |> delete("/api/goals/#{own_goal.id}")

      # Try to fail the deleted goal
      conn_fail =
        conn
        |> log_in_user(user1)
        |> post("/api/goals/#{own_goal.id}/fail", %{reason: "Should not work"})

      assert json_response(conn_fail, 404)["error"]["message"] == "Goal not found"
    end
  end

  describe "API Functionality" do
    test "users can access their own goals via /my endpoint", %{conn: conn, user1: user1} do
      conn =
        conn
        |> log_in_user(user1)
        |> get("/api/goals/my")

      response = json_response(conn, 200)
      assert is_list(response["data"])

      # All goals should belong to user1
      Enum.each(response["data"], fn goal ->
        assert goal["creator"]["id"] == user1.id
      end)
    end

    test "users can create new goals", %{conn: conn, user1: user1, group: group} do
      goal_params = %{
        title: "New Test Goal",
        description: "A goal created via API",
        privacy: "public",
        group_id: group.id,
        target_date: DateTime.to_iso8601(DateTime.add(DateTime.utc_now(), 30, :day))
      }

      conn =
        conn
        |> log_in_user(user1)
        |> post("/api/goals", %{goal: goal_params})

      response = json_response(conn, 201)
      assert response["data"]["title"] == "New Test Goal"
      assert response["data"]["creator"]["id"] == user1.id
    end

    test "goals by category endpoint works", %{conn: conn, group: group} do
      conn = get(conn, "/api/goals/category/#{group.id}")
      response = json_response(conn, 200)

      assert is_list(response["data"])
      # All goals should be from the specified category
      Enum.each(response["data"], fn goal ->
        assert goal["category"]["id"] == group.id
      end)
    end
  end

  describe "Goal Posts Ordering" do
    test "goal posts are ordered by creation date with latest first", %{
      conn: conn,
      user1: user1,
      public_goal_user1: goal
    } do
      # Create multiple posts for the goal with slight time differences
      {:ok, post1} =
        HeadsUp.Goals.create_goal_post(%{
          content: "First post",
          post_type: :update,
          goal_id: goal.id,
          user_id: user1.id
        })

      # Sleep to ensure different timestamps
      # Sleep for just over 1 second
      Process.sleep(1100)

      {:ok, post2} =
        HeadsUp.Goals.create_goal_post(%{
          content: "Second post",
          post_type: :achievement,
          goal_id: goal.id,
          user_id: user1.id
        })

      # Sleep again
      # Sleep for just over 1 second
      Process.sleep(1100)

      {:ok, post3} =
        HeadsUp.Goals.create_goal_post(%{
          content: "Third post (latest)",
          post_type: :milestone,
          goal_id: goal.id,
          user_id: user1.id
        })

      # Get the goal with posts
      conn = get(conn, "/api/goals/#{goal.id}")
      response = json_response(conn, 200)

      posts = response["data"]["recent_posts"]
      assert length(posts) == 3

      # Verify posts are ordered by creation date (latest first)
      assert List.first(posts)["content"] == "Third post (latest)"
      assert List.last(posts)["content"] == "First post"

      # Verify the order by checking timestamps (convert strings to DateTime for comparison)
      timestamps =
        Enum.map(posts, fn post ->
          {:ok, dt, _} = DateTime.from_iso8601(post["created_at"])
          dt
        end)

      assert timestamps == Enum.sort(timestamps, {:desc, DateTime})
    end

    test "goal posts include correct post type and author information", %{
      conn: conn,
      user1: user1,
      user2: user2,
      public_goal_user1: goal
    } do
      # User1 creates a post on their own goal
      {:ok, _owner_post} =
        HeadsUp.Goals.create_goal_post(%{
          content: "Owner post",
          post_type: :update,
          goal_id: goal.id,
          user_id: user1.id
        })

      # User2 creates a comment-style post (if allowed by permissions)
      {:ok, _other_post} =
        HeadsUp.Goals.create_goal_post(%{
          content: "Supportive comment",
          post_type: :motivation,
          goal_id: goal.id,
          user_id: user2.id
        })

      # Get the goal with posts
      conn = get(conn, "/api/goals/#{goal.id}")
      response = json_response(conn, 200)

      posts = response["data"]["recent_posts"]
      assert length(posts) >= 2

      # Check that posts include author information
      Enum.each(posts, fn post ->
        assert post["author"]
        assert post["author"]["id"] in [user1.id, user2.id]
        assert post["author"]["name"]
        assert post["author"]["username"]

        assert post["post_type"] in [
                 "update",
                 "achievement",
                 "milestone",
                 "challenge",
                 "motivation"
               ]
      end)
    end
  end

  describe "Goal Freeze Functionality" do
    test "users can freeze their own goals", %{
      conn: conn,
      user1: user1,
      public_goal_user1: own_goal
    } do
      conn_freeze =
        conn
        |> log_in_user(user1)
        |> post("/api/goals/#{own_goal.id}/freeze")

      response = json_response(conn_freeze, 200)
      assert response["data"]["id"] == own_goal.id
      assert response["data"]["status"] == "frozen"
      assert response["data"]["is_frozen"] == true
    end

    test "users cannot freeze other users' goals", %{
      conn: conn,
      user2: user2,
      public_goal_user1: other_goal
    } do
      conn_freeze =
        conn
        |> log_in_user(user2)
        |> post("/api/goals/#{other_goal.id}/freeze")

      assert json_response(conn_freeze, 403)["error"]["message"] ==
               "You can only freeze your own goals"
    end

    test "users can unfreeze their own goals", %{
      conn: conn,
      user1: user1,
      public_goal_user1: own_goal
    } do
      # First freeze the goal
      conn
      |> log_in_user(user1)
      |> post("/api/goals/#{own_goal.id}/freeze")

      # Then unfreeze it
      conn_unfreeze =
        conn
        |> log_in_user(user1)
        |> post("/api/goals/#{own_goal.id}/unfreeze")

      response = json_response(conn_unfreeze, 200)
      assert response["data"]["id"] == own_goal.id
      assert response["data"]["status"] == "active"
      assert response["data"]["is_frozen"] == false
    end

    test "users cannot unfreeze other users' goals", %{
      conn: conn,
      user1: user1,
      user2: user2,
      public_goal_user1: other_goal
    } do
      # First freeze the goal as owner
      conn
      |> log_in_user(user1)
      |> post("/api/goals/#{other_goal.id}/freeze")

      # Try to unfreeze as different user
      conn_unfreeze =
        conn
        |> log_in_user(user2)
        |> post("/api/goals/#{other_goal.id}/unfreeze")

      assert json_response(conn_unfreeze, 403)["error"]["message"] ==
               "You can only unfreeze your own goals"
    end

    test "frozen goals cannot be updated", %{
      conn: conn,
      user1: user1,
      public_goal_user1: own_goal
    } do
      # First freeze the goal
      conn
      |> log_in_user(user1)
      |> post("/api/goals/#{own_goal.id}/freeze")

      # Try to update the frozen goal
      conn_update =
        conn
        |> log_in_user(user1)
        |> put("/api/goals/#{own_goal.id}", %{goal: %{title: "Updated Title"}})

      assert json_response(conn_update, 403)["error"]["message"] ==
               "Frozen goals cannot be updated. Unfreeze the goal first."
    end

    test "frozen goals can be deleted", %{conn: conn, user1: user1, public_goal_user1: own_goal} do
      # First freeze the goal
      conn
      |> log_in_user(user1)
      |> post("/api/goals/#{own_goal.id}/freeze")

      # Delete the frozen goal - this should work
      conn_delete =
        conn
        |> log_in_user(user1)
        |> delete("/api/goals/#{own_goal.id}")

      assert json_response(conn_delete, 200)["message"] == "Goal deleted successfully"
    end

    test "users cannot create posts on frozen goals", %{
      conn: conn,
      user1: user1,
      public_goal_user1: own_goal
    } do
      # First freeze the goal
      conn
      |> log_in_user(user1)
      |> post("/api/goals/#{own_goal.id}/freeze")

      # Test using the Goals module directly since the API endpoint doesn't exist yet
      # Try to create a post on the frozen goal
      result =
        HeadsUp.Goals.create_goal_post_with_ownership(
          %{
            "goal_id" => own_goal.id,
            "user_id" => user1.id,
            "content" => "This should not work on frozen goal",
            "post_type" => "update"
          },
          user1.id
        )

      assert {:error, :frozen} = result
    end

    test "goal can be edited after unfreezing", %{
      conn: conn,
      user1: user1,
      public_goal_user1: own_goal
    } do
      # First freeze the goal
      conn
      |> log_in_user(user1)
      |> post("/api/goals/#{own_goal.id}/freeze")

      # Verify it cannot be updated while frozen
      conn_update_frozen =
        conn
        |> log_in_user(user1)
        |> put("/api/goals/#{own_goal.id}", %{goal: %{title: "Should Not Work"}})

      assert json_response(conn_update_frozen, 403)["error"]["message"] ==
               "Frozen goals cannot be updated. Unfreeze the goal first."

      # Unfreeze the goal
      conn
      |> log_in_user(user1)
      |> post("/api/goals/#{own_goal.id}/unfreeze")

      # Now it should be updatable
      conn_update_unfrozen =
        conn
        |> log_in_user(user1)
        |> put("/api/goals/#{own_goal.id}", %{goal: %{title: "Updated After Unfreeze"}})

      response = json_response(conn_update_unfrozen, 200)
      assert response["data"]["title"] == "Updated After Unfreeze"
      assert response["data"]["status"] == "active"
      assert response["data"]["is_frozen"] == false
    end

    test "freezing non-existent goal returns 404", %{conn: conn, user1: user1} do
      conn_freeze =
        conn
        |> log_in_user(user1)
        |> post("/api/goals/99999/freeze")

      assert json_response(conn_freeze, 404)["error"]["message"] == "Goal not found"
    end

    test "unfreezing non-existent goal returns 404", %{conn: conn, user1: user1} do
      conn_unfreeze =
        conn
        |> log_in_user(user1)
        |> post("/api/goals/99999/unfreeze")

      assert json_response(conn_unfreeze, 404)["error"]["message"] == "Goal not found"
    end

    test "freezing deleted goal returns 404", %{
      conn: conn,
      user1: user1,
      public_goal_user1: own_goal
    } do
      # First delete the goal
      conn
      |> log_in_user(user1)
      |> delete("/api/goals/#{own_goal.id}")

      # Try to freeze the deleted goal
      conn_freeze =
        conn
        |> log_in_user(user1)
        |> post("/api/goals/#{own_goal.id}/freeze")

      assert json_response(conn_freeze, 404)["error"]["message"] == "Goal not found"
    end

    test "unfreezing deleted goal returns 404", %{
      conn: conn,
      user1: user1,
      public_goal_user1: own_goal
    } do
      # First delete the goal
      conn
      |> log_in_user(user1)
      |> delete("/api/goals/#{own_goal.id}")

      # Try to unfreeze the deleted goal
      conn_unfreeze =
        conn
        |> log_in_user(user1)
        |> post("/api/goals/#{own_goal.id}/unfreeze")

      assert json_response(conn_unfreeze, 404)["error"]["message"] == "Goal not found"
    end

    test "unauthenticated users cannot freeze goals", %{conn: conn, public_goal_user1: goal} do
      conn_freeze = post(conn, "/api/goals/#{goal.id}/freeze")
      assert json_response(conn_freeze, 401)["error"]["message"] == "Authentication required"
    end

    test "unauthenticated users cannot unfreeze goals", %{conn: conn, public_goal_user1: goal} do
      conn_unfreeze = post(conn, "/api/goals/#{goal.id}/unfreeze")
      assert json_response(conn_unfreeze, 401)["error"]["message"] == "Authentication required"
    end

    test "unfreezing already active goal succeeds (idempotent operation)", %{
      conn: conn,
      user1: user1,
      public_goal_user1: active_goal
    } do
      # Try to unfreeze an already active goal - this should succeed (idempotent)
      conn_unfreeze =
        conn
        |> log_in_user(user1)
        |> post("/api/goals/#{active_goal.id}/unfreeze")

      # This should succeed because unfreeze is an idempotent operation
      response = json_response(conn_unfreeze, 200)
      assert response["data"]["id"] == active_goal.id
      assert response["data"]["status"] == "active"
      assert response["data"]["is_frozen"] == false
    end
  end

  describe "Error Handling" do
    test "accessing non-existent goal returns 404", %{conn: conn, user1: user1} do
      conn =
        conn
        |> log_in_user(user1)
        |> get("/api/goals/99999")

      assert json_response(conn, 404)["error"]["message"] == "Goal not found"
    end

    test "invalid goal ID format returns 400", %{conn: conn} do
      conn = get(conn, "/api/goals/invalid-id")
      assert json_response(conn, 400)["error"]["message"] == "Invalid goal ID"
    end

    test "accessing invalid category returns 404", %{conn: conn} do
      conn = get(conn, "/api/goals/category/99999")
      assert json_response(conn, 404)["error"]["message"] == "Category not found"
    end

    test "creating goal with invalid data returns validation errors", %{conn: conn, user1: user1} do
      invalid_goal = %{
        # Invalid: empty title
        title: "",
        description: "Test goal"
      }

      conn =
        conn
        |> log_in_user(user1)
        |> post("/api/goals", %{goal: invalid_goal})

      response = json_response(conn, 422)
      assert response["error"]["message"] == "Validation failed"
      assert response["success"] == false
    end
  end

  describe "Data Integrity" do
    test "API returns complete goal data structure", %{conn: conn, public_goal_user1: goal} do
      conn = get(conn, "/api/goals/#{goal.id}")
      response = json_response(conn, 200)

      goal_data = response["data"]

      # Check required fields are present
      assert is_integer(goal_data["id"])
      assert is_binary(goal_data["title"])
      assert is_binary(goal_data["description"])
      assert goal_data["privacy"] in ["public", "private", "friends"]
      assert goal_data["status"] in ["active", "completed", "paused", "cancelled"]
      assert is_integer(goal_data["progress"])
      assert is_integer(goal_data["likes_count"])
      assert is_integer(goal_data["subscribers_count"])

      # Check nested structures
      assert is_map(goal_data["creator"])
      assert is_integer(goal_data["creator"]["id"])
      assert is_binary(goal_data["creator"]["username"])

      assert is_map(goal_data["category"])
      assert is_integer(goal_data["category"]["id"])
      assert is_binary(goal_data["category"]["name"])

      assert is_list(goal_data["steps"])
      assert is_list(goal_data["recent_posts"])
    end

    test "goal listings have pagination metadata", %{conn: conn} do
      conn = get(conn, "/api/goals")
      response = json_response(conn, 200)

      assert is_list(response["data"])
      assert is_map(response["meta"])
      assert is_integer(response["meta"]["count"])
      assert is_map(response["meta"]["page_info"])
      assert is_boolean(response["meta"]["page_info"]["has_next_page"])
      assert is_boolean(response["meta"]["page_info"]["has_previous_page"])
    end
  end
end
