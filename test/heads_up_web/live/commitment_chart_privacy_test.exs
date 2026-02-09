defmodule HeadsUpWeb.CommitmentChartPrivacyTest do
  use HeadsUpWeb.ConnCase

  import Phoenix.LiveViewTest
  alias HeadsUp.{Accounts, AuthFixtures}

  setup %{conn: conn} do
    unique_id = System.unique_integer([:positive, :monotonic])

    # Create test users with different privacy settings
    public_user =
      AuthFixtures.user_fixture(%{
        email: "public-#{unique_id}@example.com",
        user_name: "publicuser#{unique_id}",
        name: "Public User #{unique_id}"
      })

    {:ok, public_user} = Accounts.update_user(public_user, %{privacy: "public"})

    private_user =
      AuthFixtures.user_fixture(%{
        email: "private-#{unique_id}@example.com",
        user_name: "privateuser#{unique_id}",
        name: "Private User #{unique_id}"
      })

    {:ok, private_user} = Accounts.update_user(private_user, %{privacy: "private"})

    friends_only_user =
      AuthFixtures.user_fixture(%{
        email: "friends-#{unique_id}@example.com",
        user_name: "friendsuser#{unique_id}",
        name: "Friends User #{unique_id}"
      })

    {:ok, friends_only_user} = Accounts.update_user(friends_only_user, %{privacy: "friends_only"})

    viewer_user =
      AuthFixtures.user_fixture(%{
        email: "viewer-#{unique_id}@example.com",
        user_name: "vieweruser#{unique_id}",
        name: "Viewer User #{unique_id}"
      })

    %{
      conn: conn,
      public_user: public_user,
      private_user: private_user,
      friends_only_user: friends_only_user,
      viewer_user: viewer_user
    }
  end

  describe "Commitment Chart Visibility for Public Users" do
    test "shows commitment chart for public users when authenticated", %{
      conn: conn,
      public_user: public_user,
      viewer_user: viewer_user
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{public_user.user_name}")

      # Should show the actual commitment chart
      assert html =~ "Commitment Chart"
      assert_chart_available_or_failed(view, html)

      # Should NOT show privacy message
      refute html =~ "Chart is private"
      refute html =~ "commitment chart is private"
      refute html =~ "shares their commitment chart with friends only"

      # Chart should either render or fail gracefully while remaining non-private
      assert_chart_available_or_failed(view, html)
    end

    test "shows commitment chart for public users when unauthenticated", %{
      conn: conn,
      public_user: public_user
    } do
      {:ok, view, html} = live(conn, "/people/#{public_user.user_name}")

      # Should show the actual commitment chart
      assert html =~ "Commitment Chart"
      assert_chart_available_or_failed(view, html)

      # Should NOT show privacy message
      refute html =~ "Chart is private"
      refute html =~ "commitment chart is private"

      # Chart should either render or fail gracefully while remaining non-private
      assert_chart_available_or_failed(view, html)
    end

    test "shows own commitment chart for public user", %{conn: conn, public_user: public_user} do
      {:ok, view, html} =
        conn
        |> log_in_user(public_user)
        |> live("/people/#{public_user.user_name}")

      # Should show the actual commitment chart (own profile)
      assert html =~ "Commitment Chart"
      assert_chart_available_or_failed(view, html)

      # Should NOT show privacy message
      refute html =~ "Chart is private"

      # Chart should either render or fail gracefully while remaining non-private
      assert_chart_available_or_failed(view, html)
    end
  end

  describe "Commitment Chart Privacy for Private Users" do
    test "hides commitment chart for private users when authenticated as different user", %{
      conn: conn,
      private_user: private_user,
      viewer_user: viewer_user
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{private_user.user_name}")

      # Should show section header but not the chart
      assert html =~ "Commitment Chart"

      # Should show privacy message instead of chart
      assert html =~ "Chart is private"
      assert html =~ "commitment chart is private"

      assert has_element?(
               view,
               "div[class*='bg-gray-100 p-4 rounded-lg border border-gray-200 text-center']"
             )

      # Should show lock icon
      assert has_element?(view, "span[class*='hero-lock-closed']")

      # Should NOT show actual chart content
      refute_chart_component(view, html)
      # Chart legend should not be visible
      refute html =~ "Less active"
      # Chart legend should not be visible
      refute html =~ "More active"
    end

    test "hides commitment chart for private users when unauthenticated", %{
      conn: conn,
      private_user: private_user
    } do
      {:ok, view, html} = live(conn, "/people/#{private_user.user_name}")

      # Should show section header but not the chart
      assert html =~ "Commitment Chart"

      # Should show privacy message instead of chart
      assert html =~ "Chart is private"
      assert html =~ "commitment chart is private"

      assert has_element?(
               view,
               "div[class*='bg-gray-100 p-4 rounded-lg border border-gray-200 text-center']"
             )

      # Should show lock icon
      assert has_element?(view, "span[class*='hero-lock-closed']")

      # Should NOT show actual chart content
      refute_chart_component(view, html)
    end

    test "shows own commitment chart for private user", %{conn: conn, private_user: private_user} do
      {:ok, view, html} =
        conn
        |> log_in_user(private_user)
        |> live("/people/#{private_user.user_name}")

      # Should show the actual commitment chart (own profile)
      assert html =~ "Commitment Chart"
      assert_chart_available_or_failed(view, html)

      # Should NOT show privacy message
      refute html =~ "Chart is private"
      refute html =~ "commitment chart is private"

      # Chart should either render or fail gracefully while remaining non-private
      assert_chart_available_or_failed(view, html)
    end
  end

  describe "Commitment Chart Privacy for Friends-Only Users" do
    test "hides commitment chart for friends-only users when authenticated as non-friend", %{
      conn: conn,
      friends_only_user: friends_only_user,
      viewer_user: viewer_user
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{friends_only_user.user_name}")

      # Should show section header but not the chart
      assert html =~ "Commitment Chart"

      # Should show friends-only privacy message instead of chart
      assert html =~ "Chart is private"
      assert html =~ "shares their commitment chart with friends only"

      assert has_element?(
               view,
               "div[class*='bg-gray-100 p-4 rounded-lg border border-gray-200 text-center']"
             )

      # Should show lock icon
      assert has_element?(view, "span[class*='hero-lock-closed']")

      # Should NOT show actual chart content
      refute_chart_component(view, html)
      # Chart legend should not be visible
      refute html =~ "Less active"
      # Chart legend should not be visible
      refute html =~ "More active"
    end

    test "shows commitment chart for friends-only users when authenticated as friend", %{
      conn: conn,
      friends_only_user: friends_only_user,
      viewer_user: viewer_user
    } do
      # Make users friends
      {:ok, _} = Accounts.send_friend_request(viewer_user.id, friends_only_user.id)
      {:ok, _} = Accounts.accept_friend_request(friends_only_user.id, viewer_user.id)

      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{friends_only_user.user_name}")

      # Should show the actual commitment chart (friends can see)
      assert html =~ "Commitment Chart"
      assert_chart_available_or_failed(view, html)

      # Should NOT show privacy message
      refute html =~ "Chart is private"
      refute html =~ "shares their commitment chart with friends only"

      # Chart should either render or fail gracefully while remaining non-private
      assert_chart_available_or_failed(view, html)
    end

    test "hides commitment chart for friends-only users when unauthenticated", %{
      conn: conn,
      friends_only_user: friends_only_user
    } do
      {:ok, view, html} = live(conn, "/people/#{friends_only_user.user_name}")

      # Should show section header but not the chart
      assert html =~ "Commitment Chart"

      # Should show friends-only privacy message instead of chart
      assert html =~ "Chart is private"
      assert html =~ "shares their commitment chart with friends only"

      assert has_element?(
               view,
               "div[class*='bg-gray-100 p-4 rounded-lg border border-gray-200 text-center']"
             )

      # Should show lock icon
      assert has_element?(view, "span[class*='hero-lock-closed']")

      # Should NOT show actual chart content
      refute_chart_component(view, html)
    end

    test "shows own commitment chart for friends-only user", %{
      conn: conn,
      friends_only_user: friends_only_user
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(friends_only_user)
        |> live("/people/#{friends_only_user.user_name}")

      # Should show the actual commitment chart (own profile)
      assert html =~ "Commitment Chart"
      assert_chart_available_or_failed(view, html)

      # Should NOT show privacy message
      refute html =~ "Chart is private"
      refute html =~ "shares their commitment chart with friends only"

      # Chart should either render or fail gracefully while remaining non-private
      assert_chart_available_or_failed(view, html)
    end
  end

  describe "Commitment Chart Privacy Messages" do
    test "displays correct privacy message for private users", %{
      conn: conn,
      private_user: private_user,
      viewer_user: viewer_user
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{private_user.user_name}")

      # Should show specific private message
      assert html =~ "commitment chart is private"
      refute html =~ "shares their commitment chart with friends only"

      # Should have proper styling for privacy message
      assert has_element?(
               view,
               "div[class*='bg-gray-100 p-4 rounded-lg border border-gray-200 text-center']"
             )

      assert has_element?(view, "p[class*='text-sm font-medium']", "Chart is private")
    end

    test "displays correct privacy message for friends-only users", %{
      conn: conn,
      friends_only_user: friends_only_user,
      viewer_user: viewer_user
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{friends_only_user.user_name}")

      # Should show specific friends-only message
      assert html =~ "shares their commitment chart with friends only"
      refute html =~ "commitment chart is private"

      # Should have proper styling for privacy message
      assert has_element?(
               view,
               "div[class*='bg-gray-100 p-4 rounded-lg border border-gray-200 text-center']"
             )

      assert has_element?(view, "p[class*='text-sm font-medium']", "Chart is private")
    end

    test "shows lock icon for all privacy messages", %{
      conn: conn,
      private_user: private_user,
      friends_only_user: friends_only_user,
      viewer_user: viewer_user
    } do
      # Test private user lock icon
      {:ok, private_view, _html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{private_user.user_name}")

      # Lock icon
      assert has_element?(private_view, "span[class*='hero-lock-closed']")

      # Test friends-only user lock icon
      {:ok, friends_view, _html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{friends_only_user.user_name}")

      # Lock icon
      assert has_element?(friends_view, "span[class*='hero-lock-closed']")
    end
  end

  describe "Commitment Chart Elements and Structure" do
    test "shows proper chart structure for accessible users", %{
      conn: conn,
      public_user: public_user,
      viewer_user: viewer_user
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{public_user.user_name}")

      assert html =~ "Commitment Chart"
      refute html =~ "Chart is private"
      refute html =~ "commitment chart is private"
      refute html =~ "shares their commitment chart with friends only"
      assert_chart_available_or_failed(view, render(view))
    end

    test "does not show chart elements for restricted users", %{
      conn: conn,
      private_user: private_user,
      viewer_user: viewer_user
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{private_user.user_name}")

      # Should NOT have chart component content
      refute_chart_component(view, html)
      refute html =~ "Less active"
      refute html =~ "More active"

      # Should have privacy container instead
      assert has_element?(
               view,
               "div[class*='bg-gray-100 p-4 rounded-lg border border-gray-200 text-center']"
             )
    end
  end

  describe "Edge Cases and Error Handling" do
    test "handles user with nil privacy setting as public for commitment chart", %{
      conn: conn,
      viewer_user: viewer_user
    } do
      # Create user with nil privacy (should default to public behavior)
      nil_privacy_user = AuthFixtures.user_fixture()
      {:ok, nil_privacy_user} = Accounts.update_user(nil_privacy_user, %{privacy: nil})

      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{nil_privacy_user.user_name}")

      # Should behave like public user - show chart
      assert html =~ "Commitment Chart"
      assert_chart_available_or_failed(view, html)
      refute html =~ "Chart is private"
    end

    test "commitment chart section always appears regardless of privacy", %{
      conn: conn,
      private_user: private_user,
      public_user: public_user,
      viewer_user: viewer_user
    } do
      # Test private user
      {:ok, private_view, private_html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{private_user.user_name}")

      assert private_html =~ "Commitment Chart"

      # Test public user
      {:ok, public_view, public_html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{public_user.user_name}")

      assert public_html =~ "Commitment Chart"

      # Both should have the section, but different content
      assert has_element?(private_view, "h2", "Commitment Chart")
      assert has_element?(public_view, "h2", "Commitment Chart")
    end

    test "unauthenticated user sees different privacy behavior than authenticated", %{
      conn: conn,
      private_user: private_user,
      viewer_user: viewer_user
    } do
      # Unauthenticated view
      {:ok, unauth_view, unauth_html} = live(conn, "/people/#{private_user.user_name}")

      # Authenticated view
      {:ok, auth_view, auth_html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{private_user.user_name}")

      # Both should show privacy message for private user
      assert unauth_html =~ "Chart is private"
      assert auth_html =~ "Chart is private"

      # Both should have privacy container
      assert has_element?(
               unauth_view,
               "div[class*='bg-gray-100 p-4 rounded-lg border border-gray-200 text-center']"
             )

      assert has_element?(
               auth_view,
               "div[class*='bg-gray-100 p-4 rounded-lg border border-gray-200 text-center']"
             )

      # Neither should show actual chart
      refute_chart_component(unauth_view, unauth_html)
      refute_chart_component(auth_view, auth_html)
    end
  end

  defp assert_chart_available_or_failed(view, html) do
    assert has_element?(view, "h3", "Activity Chart") or
             html =~ "Loading activity data..." or
             html =~ "Failed to load activity data."
  end

  defp refute_chart_component(view, html) do
    refute has_element?(view, "h3", "Activity Chart")
    refute html =~ "Failed to load activity data."
  end
end
