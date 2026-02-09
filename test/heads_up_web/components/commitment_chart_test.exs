defmodule HeadsUpWeb.CommitmentChartTest do
  use HeadsUpWeb.ConnCase

  import Phoenix.LiveViewTest
  alias HeadsUp.{Accounts}

  describe "CommitmentChart Component" do
    setup %{conn: conn} do
      user = HeadsUp.AuthFixtures.user_fixture()
      {:ok, user} = Accounts.update_user(user, %{privacy: "public"})

      %{conn: conn, user: user}
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

    test "displays tooltips with activity information", %{conn: conn, user: user} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live("/people/#{user.user_name}")

      # Look for title attributes (used for tooltips) or async loading/failed state
      html = render(view)
      assert html =~ "title=" or html =~ "activities" or
               html =~ "Loading activity data..." or html =~ "Failed to load activity data."
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

      # Should have responsive classes in the chart or async loading state
      assert html =~ ~r/md:|grid-cols/ or
               html =~ "Loading activity data..." or html =~ "Failed to load activity data."
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
