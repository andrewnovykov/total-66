defmodule HeadsUpWeb.ChallengeLiveTest do
  use HeadsUpWeb.ConnCase

  import Phoenix.LiveViewTest
  alias HeadsUp.ChallengesFixtures
  alias HeadsUp.AuthFixtures

  describe "Index" do
    setup %{conn: conn} do
      user = AuthFixtures.user_fixture()
      admin = AuthFixtures.admin_fixture()
      # Index page only shows templates
      template = ChallengesFixtures.official_challenge_fixture(%{user: admin})

      %{conn: conn, user: user, admin: admin, template: template}
    end

    test "lists public challenge templates for guests", %{conn: conn, template: template} do
      {:ok, _index_live, html} = live(conn, ~p"/challenges")

      assert html =~ "Challenges"
      assert html =~ template.title
    end

    test "lists templates for authenticated users", %{conn: conn, user: user, template: template} do
      conn = log_in_user(conn, user)
      {:ok, _index_live, html} = live(conn, ~p"/challenges")

      assert html =~ template.title
      assert html =~ "Create Challenge"
    end

    test "filters templates by type", %{conn: conn, admin: admin} do
      _official =
        ChallengesFixtures.official_challenge_fixture(%{
          user: admin,
          title: "Official Challenge"
        })

      community =
        ChallengesFixtures.challenge_fixture(%{
          user: AuthFixtures.user_fixture(),
          type: :community,
          is_template: true,
          title: "Community Template"
        })

      {:ok, index_live, _html} = live(conn, ~p"/challenges")

      # Filter to community only
      index_live
      |> element("select[name=type]")
      |> render_change(%{type: "community"})

      html = render(index_live)
      assert html =~ community.title
    end

    test "search filters templates", %{conn: conn} do
      admin = AuthFixtures.admin_fixture()

      _template1 =
        ChallengesFixtures.official_challenge_fixture(%{user: admin, title: "Fitness Challenge"})

      _template2 =
        ChallengesFixtures.official_challenge_fixture(%{user: admin, title: "Reading Goal"})

      {:ok, index_live, _html} = live(conn, ~p"/challenges")

      index_live
      |> element("input[name=query]")
      |> render_keyup(%{query: "Fitness"})

      html = render(index_live)
      assert html =~ "Fitness Challenge"
    end
  end

  describe "Show" do
    setup %{conn: conn} do
      user = AuthFixtures.user_fixture()
      creator = AuthFixtures.user_fixture()
      challenge = ChallengesFixtures.challenge_fixture(%{user: creator})

      %{conn: log_in_user(conn, user), user: user, creator: creator, challenge: challenge}
    end

    test "displays challenge details", %{conn: conn, challenge: challenge} do
      {:ok, _show_live, html} = live(conn, ~p"/challenges/#{challenge.id}")

      assert html =~ challenge.title
      assert html =~ "About this Challenge"
    end

    test "authenticated user can start challenge from template", %{conn: conn} do
      admin = AuthFixtures.admin_fixture()
      template = ChallengesFixtures.official_challenge_fixture(%{user: admin})

      {:ok, show_live, _html} = live(conn, ~p"/challenges/#{template.id}")

      # Click "Start Challenge" to open the modal
      show_live
      |> element("button[phx-click=start_challenge]")
      |> render_click()

      # Confirm start from the modal — now redirects to /my-challenges/:id
      {:ok, _, html} =
        show_live
        |> element("button[phx-click=confirm_start_challenge]")
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ "Challenge started"
    end

    test "owner can fail personal challenge", %{conn: conn, user: user} do
      # Create a personal challenge owned by user (not a template)
      my_challenge = ChallengesFixtures.challenge_fixture(%{user: user})
      HeadsUp.Challenges.join_challenge(my_challenge.id, user.id)

      {:ok, show_live, _html} = live(conn, ~p"/my-challenges/#{my_challenge.id}")

      # Open fail modal
      show_live
      |> element("button[phx-click=show_fail_modal]")
      |> render_click()

      # Confirm fail
      html =
        show_live
        |> element("button[phx-click=confirm_fail_challenge]")
        |> render_click()

      assert html =~ "marked as failed"
    end

    test "displays tasks for challenges", %{conn: conn, challenge: challenge} do
      _task =
        ChallengesFixtures.challenge_task_fixture(%{challenge: challenge, title: "Daily Workout"})

      {:ok, _show_live, html} = live(conn, ~p"/challenges/#{challenge.id}")

      assert html =~ "Daily Tasks"
      assert html =~ "Daily Workout"
    end
  end

  describe "New" do
    setup %{conn: conn} do
      user = AuthFixtures.user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "renders create challenge form", %{conn: conn} do
      {:ok, _new_live, html} = live(conn, ~p"/challenges/new")

      assert html =~ "Create a Challenge"
      assert html =~ "Title"
      assert html =~ "Description"
      assert html =~ "Visibility"
      assert html =~ "Duration (Days)"
      assert html =~ "Start Date"
    end

    test "creates new community challenge", %{conn: conn} do
      {:ok, new_live, _html} = live(conn, ~p"/challenges/new")

      start_date = Date.to_iso8601(Date.utc_today())

      # First add a task title (required for challenges)
      new_live
      |> element("input[phx-blur=update_task_title]")
      |> render_blur(%{value: "Daily Workout"})

      {:ok, _, html} =
        new_live
        |> form("form[phx-submit='save']",
          challenge: %{
            title: "My New Challenge",
            description: "Test desc",
            visibility: "public",
            duration_days: 30,
            start_date: start_date
          }
        )
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "My New Challenge"
      assert html =~ "Challenge created successfully"
    end

    test "validates required fields", %{conn: conn} do
      {:ok, new_live, _html} = live(conn, ~p"/challenges/new")

      html =
        new_live
        |> form("form[phx-submit='save']", challenge: %{title: ""})
        |> render_change()

      assert html =~ "Create a Challenge"
    end

    test "shows error when no task is added", %{conn: conn} do
      {:ok, new_live, _html} = live(conn, ~p"/challenges/new")

      start_date = Date.to_iso8601(Date.utc_today())

      # Submit without adding a task title
      html =
        new_live
        |> form("form[phx-submit='save']",
          challenge: %{
            title: "My Challenge",
            description: "Test",
            visibility: "public",
            duration_days: 30,
            start_date: start_date
          }
        )
        |> render_submit()

      assert html =~ "at least one task"
    end
  end

  describe "Edit" do
    setup %{conn: conn} do
      user = AuthFixtures.user_fixture()
      challenge = ChallengesFixtures.challenge_fixture(%{user: user})
      %{conn: log_in_user(conn, user), user: user, challenge: challenge}
    end

    test "renders edit form for owner", %{conn: conn, challenge: challenge} do
      {:ok, _edit_live, html} = live(conn, ~p"/challenges/#{challenge.id}/edit")

      assert html =~ "Edit Challenge"
      assert html =~ challenge.title
    end

    test "updates challenge", %{conn: conn, challenge: challenge} do
      {:ok, edit_live, _html} = live(conn, ~p"/challenges/#{challenge.id}/edit")

      {:ok, _, html} =
        edit_live
        |> form("form[phx-submit='save']", challenge: %{title: "Updated Title"})
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "Updated Title"
      assert html =~ "Challenge updated successfully"
    end

    test "deletes challenge", %{conn: conn, challenge: challenge} do
      {:ok, edit_live, _html} = live(conn, ~p"/challenges/#{challenge.id}/edit")

      {:ok, _, html} =
        edit_live
        |> element("button", "Delete")
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ "Challenge deleted successfully"
    end

    test "redirects non-owner", %{conn: conn} do
      other_user = AuthFixtures.user_fixture()
      other_challenge = ChallengesFixtures.challenge_fixture(%{user: other_user})

      {:ok, _, html} =
        live(conn, ~p"/challenges/#{other_challenge.id}/edit")
        |> follow_redirect(conn)

      assert html =~ "You can only edit your own challenges"
    end
  end

  describe "Task completion" do
    setup %{conn: conn} do
      user = AuthFixtures.user_fixture()
      creator = AuthFixtures.user_fixture()
      challenge = ChallengesFixtures.challenge_fixture(%{user: creator, type: :community})
      task = ChallengesFixtures.challenge_task_fixture(%{challenge: challenge, title: "Daily Task"})

      HeadsUp.Challenges.join_challenge(challenge.id, user.id)

      %{conn: log_in_user(conn, user), user: user, challenge: challenge, task: task}
    end

    test "participant can complete a task", %{conn: conn, challenge: challenge, task: task} do
      {:ok, show_live, _html} = live(conn, ~p"/my-challenges/#{challenge.id}")

      html =
        show_live
        |> element("button[phx-click=complete_task][phx-value-task-id=#{task.id}]")
        |> render_click()

      assert html =~ "Task completed"
    end
  end

  describe "Personal challenge UI" do
    setup %{conn: conn} do
      user = AuthFixtures.user_fixture()
      challenge = ChallengesFixtures.challenge_fixture(%{user: user})

      _task =
        ChallengesFixtures.challenge_task_fixture(%{challenge: challenge, title: "Morning Run"})

      HeadsUp.Challenges.join_challenge(challenge.id, user.id)

      %{conn: log_in_user(conn, user), user: user, challenge: challenge}
    end

    test "personal challenge shows only Fail button, not Leave/Pause/Complete/Cancel", %{
      conn: conn,
      challenge: challenge
    } do
      {:ok, _show_live, html} = live(conn, ~p"/my-challenges/#{challenge.id}")

      assert html =~ "Fail"
      refute html =~ ">Leave<"
      refute html =~ ">Pause<"
      refute html =~ ">Complete<"
      refute html =~ ">Cancel<"
    end

    test "personal challenge does not show Participants section", %{
      conn: conn,
      challenge: challenge
    } do
      {:ok, _show_live, html} = live(conn, ~p"/my-challenges/#{challenge.id}")

      refute html =~ "People who started"
    end

    test "personal challenge shows Today's Check-in section", %{conn: conn, challenge: challenge} do
      {:ok, _show_live, html} = live(conn, ~p"/my-challenges/#{challenge.id}")

      assert html =~ "Today" or html =~ "Day"
      assert html =~ "Morning Run"
    end

    test "daily check-in creates feed entry", %{conn: conn, challenge: challenge} do
      {:ok, show_live, _html} = live(conn, ~p"/my-challenges/#{challenge.id}")

      html =
        show_live
        |> element("button[phx-click=finish_day]")
        |> render_click()

      assert html =~ "Great work" or html =~ "Day completed"
      assert html =~ "Challenge Feed"
    end

    test "shows day completed after check-in", %{conn: conn, challenge: challenge} do
      {:ok, show_live, _html} = live(conn, ~p"/my-challenges/#{challenge.id}")

      show_live
      |> element("button[phx-click=finish_day]")
      |> render_click()

      html = render(show_live)
      assert html =~ "completed"
      assert html =~ "Come back tomorrow"
    end
  end

  describe "Template UI" do
    setup %{conn: conn} do
      user = AuthFixtures.user_fixture()
      admin = AuthFixtures.admin_fixture()
      template = ChallengesFixtures.official_challenge_fixture(%{user: admin})

      %{conn: log_in_user(conn, user), user: user, template: template}
    end

    test "template shows Start Challenge button", %{conn: conn, template: template} do
      {:ok, _show_live, html} = live(conn, ~p"/challenges/#{template.id}")

      assert html =~ "Start Challenge"
      refute html =~ "show_fail_modal"
    end

    test "template shows Community section", %{conn: conn, template: template} do
      {:ok, _show_live, html} = live(conn, ~p"/challenges/#{template.id}")

      assert html =~ "Community"
    end

    test "template does not show Today's Check-in", %{conn: conn, template: template} do
      {:ok, _show_live, html} = live(conn, ~p"/challenges/#{template.id}")

      refute html =~ "Today&#39;s Check-in"
      refute html =~ "Finish Day"
    end
  end

  describe "Failed challenge display" do
    setup %{conn: conn} do
      user = AuthFixtures.user_fixture()
      admin = AuthFixtures.admin_fixture()
      template = ChallengesFixtures.official_challenge_fixture(%{user: admin})

      # Create personal challenge and fail it
      challenge =
        ChallengesFixtures.challenge_fixture(%{
          user: user,
          template_id: template.id
        })

      HeadsUp.Challenges.join_challenge(challenge.id, user.id)
      HeadsUp.Challenges.fail_challenge(challenge.id, user.id, "Too difficult")

      %{conn: log_in_user(conn, user), user: user, challenge: challenge, template: template}
    end

    test "shows failed banner with reason", %{conn: conn, challenge: challenge} do
      {:ok, _show_live, html} = live(conn, ~p"/my-challenges/#{challenge.id}")

      assert html =~ "marked as failed" or html =~ "Failed"
      assert html =~ "Too difficult"
    end

    test "shows link to start again from template", %{
      conn: conn,
      challenge: challenge,
      template: template
    } do
      {:ok, _show_live, html} = live(conn, ~p"/my-challenges/#{challenge.id}")

      assert html =~ "Start again" or html =~ "/challenges/#{template.id}"
    end

    test "does not show Fail button for already-failed challenge", %{
      conn: conn,
      challenge: challenge
    } do
      {:ok, _show_live, html} = live(conn, ~p"/my-challenges/#{challenge.id}")

      refute html =~ "phx-click=\"show_fail_modal\""
    end

    test "shows Failed status badge", %{conn: conn, challenge: challenge} do
      {:ok, _show_live, html} = live(conn, ~p"/my-challenges/#{challenge.id}")

      assert html =~ "Failed"
    end
  end

  describe "BUG-1 regression: failed challenge restart" do
    setup %{conn: conn} do
      admin = AuthFixtures.admin_fixture()
      template = ChallengesFixtures.official_challenge_fixture(%{user: admin})

      %{conn: conn, admin: admin, template: template}
    end

    test "admin with many active items can still start a challenge", %{
      conn: conn,
      admin: admin,
      template: template
    } do
      # Admin creates several active challenges (would exceed free user limit of 3)
      for _i <- 1..5 do
        ChallengesFixtures.challenge_fixture(%{user: admin, status: :active})
      end

      # Admin should still be able to start from template (admins are unlimited)
      conn = log_in_user(conn, admin)
      {:ok, show_live, _html} = live(conn, ~p"/challenges/#{template.id}")

      # Click Start Challenge
      show_live |> element("button[phx-click=start_challenge]") |> render_click()

      # Confirm start
      html =
        show_live
        |> element("button[phx-click=confirm_start_challenge]")
        |> render_click()
        |> follow_redirect(conn)
        |> then(fn {:ok, _view, html} -> html end)

      assert html =~ "Challenge started"
    end

    test "free user at active limit sees clear error message", %{conn: conn, template: template} do
      free_user = AuthFixtures.user_fixture()

      # Fill up the free user's active item limit (3)
      for _i <- 1..3 do
        ChallengesFixtures.challenge_fixture(%{user: free_user, status: :active})
      end

      conn = log_in_user(conn, free_user)
      {:ok, show_live, _html} = live(conn, ~p"/challenges/#{template.id}")

      # Click Start Challenge
      show_live |> element("button[phx-click=start_challenge]") |> render_click()

      # Confirm start — should show specific error
      html = show_live |> element("button[phx-click=confirm_start_challenge]") |> render_click()

      assert html =~ "maximum of 3 active goals/challenges"
    end

    test "user who failed a challenge sees Start Again on template page", %{
      conn: conn,
      template: template
    } do
      user = AuthFixtures.user_fixture()

      # Start and fail a challenge from template
      {:ok, personal} = HeadsUp.Challenges.start_challenge_from_template(template.id, user.id)
      HeadsUp.Challenges.fail_challenge(personal.id, user.id, "Too hard")

      conn = log_in_user(conn, user)
      {:ok, _show_live, html} = live(conn, ~p"/challenges/#{template.id}")

      # Should see the failed banner with Start Again
      assert html =~ "didn&#39;t finish" or html =~ "didn't finish"
      assert html =~ "Start Again"
    end

    test "user who failed a challenge can successfully restart", %{conn: conn, template: template} do
      user = AuthFixtures.user_fixture()

      # Start and fail a challenge
      {:ok, personal} = HeadsUp.Challenges.start_challenge_from_template(template.id, user.id)
      HeadsUp.Challenges.fail_challenge(personal.id, user.id, "Too hard")

      conn = log_in_user(conn, user)
      {:ok, show_live, _html} = live(conn, ~p"/challenges/#{template.id}")

      # Click Start Again (hero button - the one with uppercase tracking)
      show_live
      |> element("button[phx-click=start_challenge][class*='uppercase']")
      |> render_click()

      # Confirm start
      html =
        show_live
        |> element("button[phx-click=confirm_start_challenge]")
        |> render_click()
        |> follow_redirect(conn)
        |> then(fn {:ok, _view, html} -> html end)

      assert html =~ "Challenge started"
    end
  end
end
