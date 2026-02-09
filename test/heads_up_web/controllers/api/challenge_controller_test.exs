defmodule HeadsUpWeb.Api.ChallengeControllerTest do
  use HeadsUpWeb.ConnCase, async: false

  alias HeadsUp.{Auth, Challenges}
  import HeadsUp.ChallengesFixtures

  setup do
    {:ok, user} =
      Auth.register_user(%{
        name: "Challenge User",
        user_name: "challenge_user",
        email: "challenge_user@test.com",
        password: "password123456"
      })

    {:ok, other_user} =
      Auth.register_user(%{
        name: "Other User",
        user_name: "other_user",
        email: "other_user@test.com",
        password: "password123456"
      })

    %{user: user, other_user: other_user}
  end

  # ============================================================================
  # Public endpoints
  # ============================================================================

  describe "GET /api/challenges" do
    test "lists public challenge templates", %{conn: conn} do
      _template = challenge_fixture(%{is_template: true, visibility: :public})

      conn = get(conn, "/api/challenges")
      assert %{"data" => challenges} = json_response(conn, 200)
      assert is_list(challenges)
    end
  end

  describe "GET /api/challenges/templates" do
    test "lists templates", %{conn: conn} do
      _template = challenge_fixture(%{is_template: true})

      conn = get(conn, "/api/challenges/templates")
      assert %{"data" => templates} = json_response(conn, 200)
      assert is_list(templates)
    end
  end

  describe "GET /api/challenges/:id" do
    test "shows a public challenge", %{conn: conn} do
      template = challenge_fixture(%{is_template: true, visibility: :public})

      conn = get(conn, "/api/challenges/#{template.id}")
      assert %{"data" => challenge} = json_response(conn, 200)
      assert challenge["id"] == template.id
      assert challenge["title"] == template.title
    end

    test "returns 404 for non-existent challenge", %{conn: conn} do
      conn = get(conn, "/api/challenges/999999")
      assert json_response(conn, 404)
    end

    test "returns 400 for invalid ID", %{conn: conn} do
      conn = get(conn, "/api/challenges/abc")
      assert json_response(conn, 400)
    end
  end

  # ============================================================================
  # Authenticated endpoints
  # ============================================================================

  describe "GET /api/challenges/my" do
    test "lists user's personal challenges", %{conn: conn, user: user} do
      challenge = challenge_fixture(%{user: user, is_template: false})
      conn = conn |> log_in_user(user) |> get("/api/challenges/my")

      assert %{"data" => challenges} = json_response(conn, 200)
      assert Enum.any?(challenges, &(&1["id"] == challenge.id))
    end

    test "returns 401 for unauthenticated", %{conn: conn} do
      conn = get(conn, "/api/challenges/my")
      assert json_response(conn, 401)
    end
  end

  describe "POST /api/challenges" do
    test "creates a community challenge", %{conn: conn, user: user} do
      params = %{
        "challenge" => %{
          "title" => "My New Challenge",
          "description" => "Testing creation",
          "type" => "community",
          "visibility" => "public",
          "duration_days" => 30,
          "start_date" => Date.to_iso8601(Date.utc_today()),
          "end_date" => Date.to_iso8601(Date.add(Date.utc_today(), 30))
        }
      }

      conn = conn |> log_in_user(user) |> post("/api/challenges", params)
      assert %{"data" => challenge} = json_response(conn, 201)
      assert challenge["title"] == "My New Challenge"
    end

    test "returns 401 for unauthenticated", %{conn: conn} do
      params = %{
        "challenge" => %{
          "title" => "Test",
          "description" => "Test",
          "type" => "community",
          "duration_days" => 30,
          "start_date" => Date.to_iso8601(Date.utc_today()),
          "end_date" => Date.to_iso8601(Date.add(Date.utc_today(), 30))
        }
      }

      conn = post(conn, "/api/challenges", params)
      assert json_response(conn, 401)
    end
  end

  describe "PUT /api/challenges/:id" do
    test "updates own challenge", %{conn: conn, user: user} do
      challenge = challenge_fixture(%{user: user})

      params = %{"challenge" => %{"title" => "Updated Title"}}
      conn = conn |> log_in_user(user) |> put("/api/challenges/#{challenge.id}", params)

      assert %{"data" => updated} = json_response(conn, 200)
      assert updated["title"] == "Updated Title"
    end

    test "returns 403 for other user's challenge", %{
      conn: conn,
      user: user,
      other_user: other_user
    } do
      challenge = challenge_fixture(%{user: other_user})

      params = %{"challenge" => %{"title" => "Hacked Title"}}
      conn = conn |> log_in_user(user) |> put("/api/challenges/#{challenge.id}", params)

      assert json_response(conn, 403)
    end
  end

  describe "DELETE /api/challenges/:id" do
    test "deletes own challenge", %{conn: conn, user: user} do
      challenge = challenge_fixture(%{user: user})

      conn = conn |> log_in_user(user) |> delete("/api/challenges/#{challenge.id}")
      assert %{"success" => true} = json_response(conn, 200)
    end

    test "returns 403 for other user's challenge", %{
      conn: conn,
      user: user,
      other_user: other_user
    } do
      challenge = challenge_fixture(%{user: other_user})

      conn = conn |> log_in_user(user) |> delete("/api/challenges/#{challenge.id}")
      assert json_response(conn, 403)
    end
  end

  # ============================================================================
  # Challenge lifecycle: start, join, leave
  # ============================================================================

  describe "POST /api/challenges/:id/start" do
    test "starts a challenge from a template", %{conn: conn, user: user} do
      template = official_challenge_fixture()

      conn = conn |> log_in_user(user) |> post("/api/challenges/#{template.id}/start")
      assert %{"data" => challenge} = json_response(conn, 201)
      assert challenge["template_id"] == template.id
      refute challenge["is_template"]
    end

    test "returns error for non-template", %{conn: conn, user: user} do
      personal = challenge_fixture(%{user: user, is_template: false})

      conn = conn |> log_in_user(user) |> post("/api/challenges/#{personal.id}/start")
      assert json_response(conn, 400)
    end
  end

  describe "POST /api/challenges/:id/join" do
    test "joins a challenge", %{conn: conn, user: user} do
      challenge = challenge_fixture(%{is_template: false})

      conn = conn |> log_in_user(user) |> post("/api/challenges/#{challenge.id}/join")
      assert %{"data" => participant} = json_response(conn, 200)
      assert participant["status"] == "active"
    end

    test "returns conflict when already joined", %{conn: conn, user: user} do
      challenge = challenge_fixture(%{is_template: false})
      Challenges.join_challenge(challenge.id, user.id)

      conn = conn |> log_in_user(user) |> post("/api/challenges/#{challenge.id}/join")
      assert json_response(conn, 409)
    end
  end

  describe "DELETE /api/challenges/:id/leave" do
    test "leaves a challenge", %{conn: conn, user: user} do
      challenge = challenge_fixture(%{is_template: false})
      Challenges.join_challenge(challenge.id, user.id)

      conn = conn |> log_in_user(user) |> delete("/api/challenges/#{challenge.id}/leave")
      assert %{"success" => true} = json_response(conn, 200)
    end

    test "returns 404 when not participating", %{conn: conn, user: user} do
      challenge = challenge_fixture(%{is_template: false})

      conn = conn |> log_in_user(user) |> delete("/api/challenges/#{challenge.id}/leave")
      assert json_response(conn, 404)
    end
  end

  # ============================================================================
  # Challenge status transitions: cancel, fail
  # ============================================================================

  describe "POST /api/challenges/:id/cancel" do
    test "cancels own active challenge", %{conn: conn, user: user} do
      challenge = challenge_fixture(%{user: user, is_template: false})
      Challenges.join_challenge(challenge.id, user.id)

      conn = conn |> log_in_user(user) |> post("/api/challenges/#{challenge.id}/cancel")
      assert %{"data" => updated} = json_response(conn, 200)
      assert updated["status"] == "cancelled"
    end

    test "returns error when already failed", %{conn: conn, user: user} do
      challenge = challenge_fixture(%{user: user, is_template: false})
      Challenges.join_challenge(challenge.id, user.id)
      Challenges.fail_challenge(challenge.id, user.id, "done")

      conn = conn |> log_in_user(user) |> post("/api/challenges/#{challenge.id}/cancel")
      assert json_response(conn, 400)
    end

    test "returns 403 for other user's challenge", %{
      conn: conn,
      user: user,
      other_user: other_user
    } do
      challenge = challenge_fixture(%{user: user, is_template: false})
      Challenges.join_challenge(challenge.id, user.id)

      conn = conn |> log_in_user(other_user) |> post("/api/challenges/#{challenge.id}/cancel")
      assert json_response(conn, 403)
    end
  end

  describe "POST /api/challenges/:id/fail" do
    test "fails own challenge with reason", %{conn: conn, user: user} do
      challenge = challenge_fixture(%{user: user, is_template: false})
      Challenges.join_challenge(challenge.id, user.id)

      conn =
        conn
        |> log_in_user(user)
        |> post("/api/challenges/#{challenge.id}/fail", %{"reason" => "Too busy"})

      assert %{"data" => updated} = json_response(conn, 200)
      assert updated["status"] == "failed"
      assert updated["failure_reason"] == "Too busy"
    end

    test "returns 400 without reason", %{conn: conn, user: user} do
      challenge = challenge_fixture(%{user: user, is_template: false})
      Challenges.join_challenge(challenge.id, user.id)

      conn =
        conn |> log_in_user(user) |> post("/api/challenges/#{challenge.id}/fail", %{})

      assert json_response(conn, 400)
    end

    test "returns 403 for other user's challenge", %{
      conn: conn,
      user: user,
      other_user: other_user
    } do
      challenge = challenge_fixture(%{user: user, is_template: false})
      Challenges.join_challenge(challenge.id, user.id)

      conn =
        conn
        |> log_in_user(other_user)
        |> post("/api/challenges/#{challenge.id}/fail", %{"reason" => "Hacking"})

      assert json_response(conn, 403)
    end
  end

  # ============================================================================
  # Share as template
  # ============================================================================

  describe "POST /api/challenges/:id/share" do
    test "shares own challenge as template", %{conn: conn, user: user} do
      challenge = challenge_fixture(%{user: user, is_template: false})

      conn = conn |> log_in_user(user) |> post("/api/challenges/#{challenge.id}/share")
      assert %{"data" => template} = json_response(conn, 201)
      assert template["is_template"] == true
    end

    test "returns 403 for other user's challenge", %{
      conn: conn,
      user: user,
      other_user: other_user
    } do
      challenge = challenge_fixture(%{user: other_user, is_template: false})

      conn = conn |> log_in_user(user) |> post("/api/challenges/#{challenge.id}/share")
      assert json_response(conn, 403)
    end
  end

  # ============================================================================
  # Progress and today's items
  # ============================================================================

  describe "GET /api/challenges/:id/progress" do
    test "returns progress for participant", %{conn: conn, user: user} do
      challenge = challenge_fixture(%{user: user, is_template: false})
      Challenges.join_challenge(challenge.id, user.id)

      conn = conn |> log_in_user(user) |> get("/api/challenges/#{challenge.id}/progress")
      assert %{"data" => progress} = json_response(conn, 200)
      assert is_number(progress["total_days"])
    end

    test "returns 404 for non-participant", %{conn: conn, user: user} do
      challenge = challenge_fixture(%{is_template: false})

      conn = conn |> log_in_user(user) |> get("/api/challenges/#{challenge.id}/progress")
      assert json_response(conn, 404)
    end
  end

  describe "GET /api/challenges/:id/today" do
    test "returns today's items for participant", %{conn: conn, user: user} do
      challenge = challenge_fixture(%{user: user, is_template: false})
      _task = challenge_task_fixture(%{challenge: challenge, title: "Daily Task"})
      Challenges.join_challenge(challenge.id, user.id)

      conn = conn |> log_in_user(user) |> get("/api/challenges/#{challenge.id}/today")
      assert %{"data" => today} = json_response(conn, 200)
      assert today["type"] == "tasks"
      assert is_list(today["items"])
    end
  end

  # ============================================================================
  # Step and task completion
  # ============================================================================

  describe "POST /api/challenges/:id/tasks/:task_id/complete" do
    test "completes a task", %{conn: conn, user: user} do
      challenge = challenge_fixture(%{user: user, is_template: false})
      task = challenge_task_fixture(%{challenge: challenge})
      Challenges.join_challenge(challenge.id, user.id)

      conn =
        conn
        |> log_in_user(user)
        |> post("/api/challenges/#{challenge.id}/tasks/#{task.id}/complete")

      assert %{"success" => true} = json_response(conn, 200)
    end

    test "returns 404 for non-participant", %{conn: conn, user: user} do
      challenge = challenge_fixture(%{is_template: false})
      task = challenge_task_fixture(%{challenge: challenge})

      conn =
        conn
        |> log_in_user(user)
        |> post("/api/challenges/#{challenge.id}/tasks/#{task.id}/complete")

      assert json_response(conn, 404)
    end
  end

  # ============================================================================
  # Daily check-in
  # ============================================================================

  describe "POST /api/challenges/:id/check-in" do
    test "creates a daily check-in", %{conn: conn, user: user} do
      challenge = challenge_fixture(%{user: user, is_template: false})
      _task = challenge_task_fixture(%{challenge: challenge})
      Challenges.join_challenge(challenge.id, user.id)

      params = %{
        "check_in" => %{
          "note" => "Feeling good today!",
          "mood" => "good"
        }
      }

      conn =
        conn
        |> log_in_user(user)
        |> post("/api/challenges/#{challenge.id}/check-in", params)

      assert %{"data" => check_in} = json_response(conn, 201)
      assert check_in["note"] == "Feeling good today!"
      assert check_in["mood"] == "good"
    end

    test "returns conflict for duplicate check-in", %{conn: conn, user: user} do
      challenge = challenge_fixture(%{user: user, is_template: false})
      _task = challenge_task_fixture(%{challenge: challenge})
      Challenges.join_challenge(challenge.id, user.id)

      participant = Challenges.get_participant(challenge.id, user.id)
      Challenges.create_daily_check_in(participant.id, %{note: "First", mood: "good"})

      params = %{"check_in" => %{"note" => "Second", "mood" => "ok"}}

      conn =
        conn
        |> log_in_user(user)
        |> post("/api/challenges/#{challenge.id}/check-in", params)

      assert json_response(conn, 409)
    end
  end

  # ============================================================================
  # Feed
  # ============================================================================

  describe "GET /api/challenges/:id/feed" do
    test "returns challenge feed for authenticated user", %{conn: conn, user: user} do
      challenge = challenge_fixture(%{user: user, is_template: false})

      conn = conn |> log_in_user(user) |> get("/api/challenges/#{challenge.id}/feed")
      assert %{"data" => feed} = json_response(conn, 200)
      assert is_list(feed)
    end
  end
end
