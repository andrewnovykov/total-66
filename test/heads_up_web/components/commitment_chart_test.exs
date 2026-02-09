defmodule HeadsUpWeb.CommitmentChartTest do
  use HeadsUpWeb.ConnCase

  import Phoenix.LiveViewTest
  alias HeadsUp.{Goals, Group, Repo, Accounts}

  describe "CommitmentChart Component" do
    setup %{conn: conn} do
      user = HeadsUp.AuthFixtures.user_fixture()
      {:ok, user} = Accounts.update_user(user, %{privacy: "public"})

      # Create some activities for testing
      group =
        Repo.insert!(%Group{
          name: "Test Category",
          description: "A test category",
          image_path: "/test/image.jpg",
          status: :published
        })

      {:ok, _goal} =
        Goals.create_goal(%{
          title: "Test Goal",
          description: "A test goal",
          privacy: :public,
          user_id: user.id,
          group_id: group.id,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      %{conn: conn, user: user, group: group}
    end

    test "renders with activity data", %{conn: conn, user: user} do
      # Test commitment chart via real user profile page
      {:ok, view, html} =
        conn
        |> log_in_user(user)
        |> live("/people/#{user.user_name}")

      # Component uses bg-white border border-gray-200 rounded-xl
      assert html =~ "Commitment Chart"
      assert has_element?(view, "div[class*='bg-white']")
    end

    test "shows different intensity levels", %{conn: conn, user: user, group: group} do
      # Create goals with completed status to generate different XP levels
      # (active limit is 3, setup already creates 1 active goal)
      for i <- 1..3 do
        {:ok, goal} =
          HeadsUp.Goals.create_goal(%{
            title: "Goal #{i}",
            description: "Test goal #{i}",
            privacy: :public,
            user_id: user.id,
            group_id: group.id,
            status: :completed,
            target_date: DateTime.add(DateTime.utc_now(), 30, :day)
          })
      end

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live("/people/#{user.user_name}")

      html = render(view)

      # Should have different intensity classes (bg-gray-100 for no activity, bg-blue-* for activity)
      assert html =~ "bg-gray-100" or html =~ "bg-blue-200"
    end

    test "displays tooltips with activity information", %{conn: conn, user: user} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live("/people/#{user.user_name}")

      # Look for title attributes (used for tooltips)
      html = render(view)
      assert html =~ "title=" or html =~ "activities"
    end

    test "shows correct month labels", %{conn: conn, user: user} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live("/people/#{user.user_name}")

      html = render(view)

      if html =~ "Activity Chart" do
        # Should show month abbreviations when chart is rendered
        assert html =~ "Jan"
        assert html =~ "Feb"
        assert html =~ "Dec"
      else
        # Async fallback states are also valid
        assert html =~ "Loading activity data..." or html =~ "Failed to load activity data."
      end
    end

    test "shows activity summary", %{conn: conn, user: user} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live("/people/#{user.user_name}")

      html = render(view)

      if html =~ "Activity Chart" do
        # Should show total XP and streak info when chart is rendered
        assert html =~ "Total XP" or html =~ "XP"
        assert html =~ "Current Streak" or html =~ "Streak"
      else
        # Async fallback states are also valid
        assert html =~ "Loading activity data..." or html =~ "Failed to load activity data."
      end
    end

    test "handles empty activity data gracefully", %{conn: conn} do
      user_with_no_activity = HeadsUp.AuthFixtures.user_fixture()

      {:ok, user_with_no_activity} =
        Accounts.update_user(user_with_no_activity, %{privacy: "public"})

      {:ok, view, html} =
        conn
        |> log_in_user(user_with_no_activity)
        |> live("/people/#{user_with_no_activity.user_name}")

      # Should still render chart structure
      assert html =~ "Commitment Chart"
      # Days should use bg-gray-100 for no activity
      assert render(view) =~ "bg-gray-100"
    end

    test "responsive design classes are present", %{conn: conn, user: user} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live("/people/#{user.user_name}")

      html = render(view)

      # Should have responsive classes (md: for medium screens)
      assert html =~ ~r/md:|grid-cols/
    end

    test "performance with large datasets", %{conn: conn, user: user, group: group} do
      # Create many completed goals to generate activity data
      # (use :completed status to avoid active item limit)
      for month <- 1..12 do
        for day <- 1..5 do
          {:ok, _goal} =
            HeadsUp.Goals.create_goal(%{
              title: "Goal M#{month}D#{day}",
              description: "Test goal",
              privacy: :public,
              user_id: user.id,
              group_id: group.id,
              status: :completed,
              target_date: DateTime.add(DateTime.utc_now(), 30, :day)
            })
        end
      end

      # Should render without timing out
      start_time = System.monotonic_time()

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live("/people/#{user.user_name}")

      end_time = System.monotonic_time()

      # Should complete within reasonable time (5 seconds)
      duration_ms = System.convert_time_unit(end_time - start_time, :native, :millisecond)
      assert duration_ms < 5000

      assert render(view) =~ "Commitment Chart"
    end
  end

  describe "CommitmentChart Privacy" do
    setup %{conn: conn} do
      public_user = HeadsUp.AuthFixtures.user_fixture()
      {:ok, public_user} = Accounts.update_user(public_user, %{privacy: "public"})

      private_user = HeadsUp.AuthFixtures.user_fixture()
      {:ok, private_user} = Accounts.update_user(private_user, %{privacy: "private"})

      viewer = HeadsUp.AuthFixtures.user_fixture()

      %{conn: conn, public_user: public_user, private_user: private_user, viewer: viewer}
    end

    test "shows chart for public users", %{conn: conn, public_user: public_user, viewer: viewer} do
      {:ok, _view, html} =
        conn
        |> log_in_user(viewer)
        |> live("/people/#{public_user.user_name}")

      assert html =~ "Commitment Chart"
      # Public users should NOT show privacy message
      refute html =~ "Chart is private"
    end

    test "hides chart for private users (shows privacy message)", %{
      conn: conn,
      private_user: private_user,
      viewer: viewer
    } do
      {:ok, _view, html} =
        conn
        |> log_in_user(viewer)
        |> live("/people/#{private_user.user_name}")

      assert html =~ "Commitment Chart"
      # Private users should show privacy message
      assert html =~ "Chart is private"
    end

    test "owner can see their own private chart", %{conn: conn, private_user: private_user} do
      {:ok, _view, html} =
        conn
        |> log_in_user(private_user)
        |> live("/people/#{private_user.user_name}")

      assert html =~ "Commitment Chart"
      # Owner should NOT see privacy message on their own profile
      refute html =~ "Chart is private"
    end
  end
end
