defmodule HeadsUpWeb.CommitmentChartEnhancedTest do
  use HeadsUpWeb.ConnCase

  import Phoenix.LiveViewTest
  alias HeadsUp.{Accounts, AuthFixtures}

  setup %{conn: conn} do
    unique_id = System.unique_integer([:positive, :monotonic])

    # Create test users with explicit privacy settings
    public_user =
      AuthFixtures.user_fixture(%{
        email: "enhanced-public-#{unique_id}@example.com",
        user_name: "enhancedpublic#{unique_id}",
        name: "Enhanced Public #{unique_id}"
      })

    {:ok, public_user} = Accounts.update_user(public_user, %{privacy: "public"})

    private_user =
      AuthFixtures.user_fixture(%{
        email: "enhanced-private-#{unique_id}@example.com",
        user_name: "enhancedprivate#{unique_id}",
        name: "Enhanced Private #{unique_id}"
      })

    {:ok, private_user} = Accounts.update_user(private_user, %{privacy: "private"})

    friends_only_user =
      AuthFixtures.user_fixture(%{
        email: "enhanced-friends-#{unique_id}@example.com",
        user_name: "enhancedfriends#{unique_id}",
        name: "Enhanced Friends #{unique_id}"
      })

    {:ok, friends_only_user} = Accounts.update_user(friends_only_user, %{privacy: "friends_only"})

    nil_privacy_user =
      AuthFixtures.user_fixture(%{
        email: "enhanced-nil-#{unique_id}@example.com",
        user_name: "enhancednil#{unique_id}",
        name: "Enhanced Nil #{unique_id}"
      })

    {:ok, nil_privacy_user} = Accounts.update_user(nil_privacy_user, %{privacy: nil})

    viewer_user =
      AuthFixtures.user_fixture(%{
        email: "enhanced-viewer-#{unique_id}@example.com",
        user_name: "enhancedviewer#{unique_id}",
        name: "Enhanced Viewer #{unique_id}"
      })

    %{
      conn: conn,
      public_user: public_user,
      private_user: private_user,
      friends_only_user: friends_only_user,
      nil_privacy_user: nil_privacy_user,
      viewer_user: viewer_user
    }
  end

  describe "Real-world Commitment Chart Privacy Scenarios" do
    test "public user shows chart to everyone", %{
      conn: conn,
      public_user: public_user,
      viewer_user: viewer_user
    } do
      # Test authenticated user viewing public profile
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{public_user.user_name}")

      assert html =~ "Commitment Chart"
      # Should show the actual chart container
      assert_chart_available_or_failed(view, html)
      refute html =~ "Chart is private"

      # Test unauthenticated user viewing public profile
      {:ok, unauth_view, unauth_html} = live(conn, "/people/#{public_user.user_name}")

      assert unauth_html =~ "Commitment Chart"
      assert_chart_available_or_failed(unauth_view, unauth_html)
      refute unauth_html =~ "Chart is private"
    end

    test "private user hides chart from non-owners", %{
      conn: conn,
      private_user: private_user,
      viewer_user: viewer_user
    } do
      # Test non-owner authenticated user viewing private profile
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{private_user.user_name}")

      assert html =~ "Commitment Chart"
      # Should show privacy message, not actual chart
      assert has_element?(
               view,
               "div[class*='bg-gray-100 p-4 rounded-lg border border-gray-200 text-center']"
             )

      assert html =~ "Chart is private"
      refute_chart_component(view, html)

      # Test unauthenticated user viewing private profile
      {:ok, unauth_view, unauth_html} = live(conn, "/people/#{private_user.user_name}")

      assert unauth_html =~ "Commitment Chart"

      assert has_element?(
               unauth_view,
               "div[class*='bg-gray-100 p-4 rounded-lg border border-gray-200 text-center']"
             )

      assert unauth_html =~ "Chart is private"
      refute_chart_component(unauth_view, unauth_html)
    end

    test "private user shows chart to owner", %{conn: conn, private_user: private_user} do
      # Test owner viewing their own private profile
      {:ok, view, html} =
        conn
        |> log_in_user(private_user)
        |> live("/people/#{private_user.user_name}")

      assert html =~ "Commitment Chart"
      # Owner should see actual chart
      assert_chart_available_or_failed(view, html)
      refute html =~ "Chart is private"
    end

    test "friends-only user hides chart from non-friends", %{
      conn: conn,
      friends_only_user: friends_only_user,
      viewer_user: viewer_user
    } do
      # Test non-friend viewing friends-only profile
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{friends_only_user.user_name}")

      assert html =~ "Commitment Chart"

      assert has_element?(
               view,
               "div[class*='bg-gray-100 p-4 rounded-lg border border-gray-200 text-center']"
             )

      assert html =~ "Chart is private"
      assert html =~ "shares their commitment chart with friends only"
      refute_chart_component(view, html)
    end

    test "friends-only user shows chart to friends", %{
      conn: conn,
      friends_only_user: friends_only_user,
      viewer_user: viewer_user
    } do
      # Make users friends
      {:ok, _} = Accounts.send_friend_request(viewer_user.id, friends_only_user.id)
      {:ok, _} = Accounts.accept_friend_request(friends_only_user.id, viewer_user.id)

      # Test friend viewing friends-only profile
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{friends_only_user.user_name}")

      assert html =~ "Commitment Chart"
      # Friend should see actual chart
      assert_chart_available_or_failed(view, html)
      refute html =~ "Chart is private"
    end

    test "nil privacy defaults to public behavior", %{
      conn: conn,
      nil_privacy_user: nil_privacy_user,
      viewer_user: viewer_user
    } do
      # Test that nil privacy behaves like public
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{nil_privacy_user.user_name}")

      assert html =~ "Commitment Chart"
      # Should show actual chart like public user
      assert_chart_available_or_failed(view, html)
      refute html =~ "Chart is private"
    end
  end

  describe "Database Privacy Verification" do
    test "verify user privacy settings are stored correctly", %{
      public_user: public_user,
      private_user: private_user,
      friends_only_user: friends_only_user,
      nil_privacy_user: nil_privacy_user
    } do
      # Refresh users from database to verify privacy settings
      public_user = Accounts.get_user(public_user.id)
      private_user = Accounts.get_user(private_user.id)
      friends_only_user = Accounts.get_user(friends_only_user.id)
      nil_privacy_user = Accounts.get_user(nil_privacy_user.id)

      assert public_user.privacy == "public"
      assert private_user.privacy == "private"
      assert friends_only_user.privacy == "friends_only"
      assert nil_privacy_user.privacy == nil
    end
  end

  describe "Edge Cases and Debugging" do
    test "test with server restart simulation", %{
      conn: conn,
      private_user: private_user,
      viewer_user: viewer_user
    } do
      # Test privacy immediately after mount (simulating fresh page load)
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{private_user.user_name}")

      # Should immediately show privacy message
      assert html =~ "Chart is private"
      refute_chart_component(view, html)

      # Verify no cache corruption by navigating away and back
      {:ok, view2, html2} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{private_user.user_name}")

      assert html2 =~ "Chart is private"
      refute_chart_component(view2, html2)
    end
  end

  defp assert_chart_available_or_failed(view, html) do
    assert has_element?(view, "h3", "Activity Chart") or
             html =~ "Loading activity data..." or
             html =~ "Failed to load activity data."
  end

  defp refute_chart_component(view, html) do
    refute has_element?(view, "h3", "Activity Chart")
    refute html =~ "Loading activity data..."
    refute html =~ "Failed to load activity data."
  end
end
