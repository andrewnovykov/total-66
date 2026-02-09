defmodule HeadsUpWeb.UsersLive.ShowSocialTest do
  use HeadsUpWeb.ConnCase

  import Phoenix.LiveViewTest
  import HeadsUp.DataCase, only: [errors_on: 1]
  alias HeadsUp.{Accounts, AuthFixtures}

  setup %{conn: conn} do
    # Create test users with different privacy settings
    public_user = AuthFixtures.user_fixture()
    {:ok, public_user} = Accounts.update_user(public_user, %{privacy: "public"})

    private_user = AuthFixtures.user_fixture()
    {:ok, private_user} = Accounts.update_user(private_user, %{privacy: "private"})

    friends_only_user = AuthFixtures.user_fixture()
    {:ok, friends_only_user} = Accounts.update_user(friends_only_user, %{privacy: "friends_only"})

    viewer_user = AuthFixtures.user_fixture()

    %{
      conn: conn,
      public_user: public_user,
      private_user: private_user,
      friends_only_user: friends_only_user,
      viewer_user: viewer_user
    }
  end

  describe "Public User Profile" do
    test "shows follow button for public users", %{
      conn: conn,
      public_user: public_user,
      viewer_user: viewer_user
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{public_user.user_name}")

      # Should show follow button
      assert has_element?(view, "button[phx-click=\"toggle_follow\"]")
      assert html =~ "Follow"

      # Should show add friend button
      assert has_element?(view, "button[phx-click=\"send_friend_request\"]")
      assert html =~ "Add Friend"
    end

    test "can follow and unfollow public users", %{
      conn: conn,
      public_user: public_user,
      viewer_user: viewer_user
    } do
      {:ok, view, _html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{public_user.user_name}")

      # Initially should show Follow
      assert has_element?(view, "button", "Follow")

      # Click follow
      view |> element("button[phx-click=\"toggle_follow\"]") |> render_click()

      # Should now show Unfollow
      assert has_element?(view, "button", "Unfollow")

      # Click unfollow
      view |> element("button[phx-click=\"toggle_follow\"]") |> render_click()

      # Should show Follow again
      assert has_element?(view, "button", "Follow")
    end

    test "can send friend request to public users", %{
      conn: conn,
      public_user: public_user,
      viewer_user: viewer_user
    } do
      {:ok, view, _html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{public_user.user_name}")

      # Should show Add Friend button
      assert has_element?(view, "button", "Add Friend")

      # Send friend request
      view |> element("button[phx-click=\"send_friend_request\"]") |> render_click()

      # Should show success message
      assert render(view) =~ "Friend request sent"

      # Button should change to Cancel Request
      assert has_element?(view, "button", "Cancel Request")
    end

    test "can cancel sent friend request", %{
      conn: conn,
      public_user: public_user,
      viewer_user: viewer_user
    } do
      # Send friend request first
      {:ok, _} = Accounts.send_friend_request(viewer_user.id, public_user.id)

      {:ok, view, _html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{public_user.user_name}")

      # Should show Cancel Request button
      assert has_element?(view, "button", "Cancel Request")

      # Cancel the request
      view |> element("button[phx-click=\"cancel_friend_request\"]") |> render_click()

      # Should show success message
      assert render(view) =~ "Friend request cancelled"

      # Button should change back to Add Friend
      assert has_element?(view, "button", "Add Friend")
    end
  end

  describe "Private User Profile" do
    test "does not show follow button for private users", %{
      conn: conn,
      private_user: private_user,
      viewer_user: viewer_user
    } do
      # Verify the user is actually private
      assert private_user.privacy == "private"

      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{private_user.user_name}")

      # Should NOT show follow button (since can_follow is false)
      refute has_element?(view, "button[phx-click=\"toggle_follow\"]")
      # Check for the specific follow button text, not just "Follow" which could be in "Following"
      refute has_element?(view, "button", "Follow")

      # Should still show add friend button for private users
      assert has_element?(view, "button[phx-click=\"send_friend_request\"]")
      assert html =~ "Add Friend"
    end

    test "shows error when trying to follow private user through API", %{
      conn: conn,
      private_user: private_user,
      viewer_user: viewer_user
    } do
      # Manually try to follow private user through Accounts module
      result = Accounts.follow_user(viewer_user.id, private_user.id)
      assert {:error, :user_is_private} = result
    end

    test "can send friend requests to private users", %{
      conn: conn,
      private_user: private_user,
      viewer_user: viewer_user
    } do
      {:ok, view, _html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{private_user.user_name}")

      # Should show Add Friend button
      assert has_element?(view, "button", "Add Friend")

      # Send friend request
      view |> element("button[phx-click=\"send_friend_request\"]") |> render_click()

      # Should show success message
      assert render(view) =~ "Friend request sent"

      # Button should change to Cancel Request
      assert has_element?(view, "button", "Cancel Request")
    end
  end

  describe "Friends-Only User Profile" do
    test "does not show follow button for non-friends", %{
      conn: conn,
      friends_only_user: friends_only_user,
      viewer_user: viewer_user
    } do
      # Verify the user is actually friends_only
      assert friends_only_user.privacy == "friends_only"

      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{friends_only_user.user_name}")

      # Should NOT show follow button (since can_follow is false for non-friends)
      refute has_element?(view, "button[phx-click=\"toggle_follow\"]")
      # Check for the specific follow button text, not just "Follow" which could be in "Following"
      refute has_element?(view, "button", "Follow")

      # Should show add friend button
      assert has_element?(view, "button[phx-click=\"send_friend_request\"]")
      assert html =~ "Add Friend"
    end

    test "shows follow button after becoming friends", %{
      conn: conn,
      friends_only_user: friends_only_user,
      viewer_user: viewer_user
    } do
      # Become friends first
      {:ok, _} = Accounts.send_friend_request(viewer_user.id, friends_only_user.id)
      {:ok, _} = Accounts.accept_friend_request(friends_only_user.id, viewer_user.id)

      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{friends_only_user.user_name}")

      # Should now show follow button (since they are friends)
      assert has_element?(view, "button[phx-click=\"toggle_follow\"]")
      assert html =~ "Follow"

      # Should show Remove Friend button
      assert has_element?(view, "button", "Remove Friend")
    end

    test "can follow friends-only user after friendship established", %{
      conn: conn,
      friends_only_user: friends_only_user,
      viewer_user: viewer_user
    } do
      # Become friends first
      {:ok, _} = Accounts.send_friend_request(viewer_user.id, friends_only_user.id)
      {:ok, _} = Accounts.accept_friend_request(friends_only_user.id, viewer_user.id)

      {:ok, view, _html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{friends_only_user.user_name}")

      # Should show Follow button
      assert has_element?(view, "button", "Follow")

      # Can follow
      view |> element("button[phx-click=\"toggle_follow\"]") |> render_click()

      # Should show Unfollow
      assert has_element?(view, "button", "Unfollow")
    end
  end

  describe "Friend Request Management" do
    test "shows accept/decline buttons for incoming friend requests", %{
      conn: conn,
      public_user: public_user,
      viewer_user: viewer_user
    } do
      # viewer_user receives friend request from public_user
      {:ok, _} = Accounts.send_friend_request(public_user.id, viewer_user.id)

      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{public_user.user_name}")

      # Should show Accept and Decline buttons
      assert has_element?(view, "button", "Accept")
      assert has_element?(view, "button", "Decline")
      assert html =~ "Accept"
      assert html =~ "Decline"
    end

    test "can accept friend requests", %{
      conn: conn,
      public_user: public_user,
      viewer_user: viewer_user
    } do
      # viewer_user receives friend request from public_user
      {:ok, _} = Accounts.send_friend_request(public_user.id, viewer_user.id)

      {:ok, view, _html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{public_user.user_name}")

      # Accept the request
      view |> element("button[phx-click=\"accept_friend_request\"]") |> render_click()

      # Should show success message
      assert render(view) =~ "Friend request accepted"

      # Should now show Remove Friend button
      assert has_element?(view, "button", "Remove Friend")
    end

    test "can decline friend requests", %{
      conn: conn,
      public_user: public_user,
      viewer_user: viewer_user
    } do
      # viewer_user receives friend request from public_user
      {:ok, _} = Accounts.send_friend_request(public_user.id, viewer_user.id)

      {:ok, view, _html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{public_user.user_name}")

      # Decline the request
      view |> element("button[phx-click=\"decline_friend_request\"]") |> render_click()

      # Should show success message
      assert render(view) =~ "Friend request declined"

      # Should now show Add Friend button again
      assert has_element?(view, "button", "Add Friend")
    end

    test "can remove friends", %{conn: conn, public_user: public_user, viewer_user: viewer_user} do
      # Establish friendship
      {:ok, _} = Accounts.send_friend_request(viewer_user.id, public_user.id)
      {:ok, _} = Accounts.accept_friend_request(public_user.id, viewer_user.id)

      {:ok, view, _html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{public_user.user_name}")

      # Should show Remove Friend button
      assert has_element?(view, "button", "Remove Friend")

      # Remove friend
      view |> element("button[phx-click=\"remove_friend\"]") |> render_click()

      # Should show success message
      assert render(view) =~ "Friend removed"

      # Should now show Add Friend button again
      assert has_element?(view, "button", "Add Friend")
    end
  end

  describe "Button States and Visibility" do
    test "no social buttons shown for own profile", %{conn: conn, viewer_user: viewer_user} do
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{viewer_user.user_name}")

      # Should not show any social interaction buttons for own profile
      refute has_element?(view, "button[phx-click=\"toggle_follow\"]")
      refute has_element?(view, "button[phx-click=\"send_friend_request\"]")
      refute html =~ "Follow"
      refute html =~ "Add Friend"
    end

    test "unauthenticated users see no interaction buttons", %{
      conn: conn,
      public_user: public_user
    } do
      {:ok, view, html} = live(conn, "/people/#{public_user.user_name}")

      # Should not show any interaction buttons for unauthenticated users
      refute has_element?(view, "button[phx-click=\"toggle_follow\"]")
      refute has_element?(view, "button[phx-click=\"send_friend_request\"]")
      refute html =~ "Follow"
      refute html =~ "Add Friend"
    end

    test "correct button combinations for different states", %{
      conn: conn,
      public_user: public_user,
      viewer_user: viewer_user
    } do
      {:ok, view, _html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{public_user.user_name}")

      # Initial state: Follow + Add Friend
      assert has_element?(view, "button", "Follow")
      assert has_element?(view, "button", "Add Friend")

      # After following: Unfollow + Add Friend
      view |> element("button[phx-click=\"toggle_follow\"]") |> render_click()
      assert has_element?(view, "button", "Unfollow")
      assert has_element?(view, "button", "Add Friend")

      # After sending friend request: Unfollow + Cancel Request
      view |> element("button[phx-click=\"send_friend_request\"]") |> render_click()
      assert has_element?(view, "button", "Unfollow")
      assert has_element?(view, "button", "Cancel Request")
    end
  end

  describe "Error Handling" do
    test "shows appropriate error messages for failed operations", %{
      conn: conn,
      private_user: private_user,
      viewer_user: viewer_user
    } do
      # Try to follow a private user via the follow_user function directly
      result = Accounts.follow_user(viewer_user.id, private_user.id)
      assert {:error, :user_is_private} = result
    end

    test "handles non-existent user gracefully", %{conn: conn, viewer_user: viewer_user} do
      assert {:error, {:live_redirect, %{to: "/people"}}} =
               conn
               |> log_in_user(viewer_user)
               |> live("/people/nonexistent-user")
    end

    test "requires authentication for social actions", %{conn: conn, public_user: public_user} do
      {:ok, view, _html} = live(conn, "/people/#{public_user.user_name}")

      # Attempting to click follow without authentication should do nothing
      # (buttons shouldn't exist for unauthenticated users)
      refute has_element?(view, "button[phx-click=\"toggle_follow\"]")
      refute has_element?(view, "button[phx-click=\"send_friend_request\"]")
    end
  end

  describe "Privacy Setting Edge Cases" do
    test "handles nil privacy setting as public", %{conn: conn, viewer_user: viewer_user} do
      # Create user with nil privacy (should default to public behavior)
      nil_privacy_user = AuthFixtures.user_fixture()
      {:ok, nil_privacy_user} = Accounts.update_user(nil_privacy_user, %{privacy: nil})

      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{nil_privacy_user.user_name}")

      # Should behave like public user
      assert has_element?(view, "button[phx-click=\"toggle_follow\"]")
      assert html =~ "Follow"
      assert has_element?(view, "button[phx-click=\"send_friend_request\"]")
      assert html =~ "Add Friend"
    end

    test "handles invalid privacy setting as public", %{conn: conn, viewer_user: viewer_user} do
      # Create user with invalid privacy setting - this should be rejected by changeset
      invalid_privacy_user = AuthFixtures.user_fixture()

      # Try to update with invalid privacy - should fail validation
      assert {:error, changeset} =
               Accounts.update_user(invalid_privacy_user, %{privacy: "invalid_setting"})

      assert "is invalid" in errors_on(changeset).privacy

      # Test that user still works with default privacy (public)
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{invalid_privacy_user.user_name}")

      # Should behave like public user (since privacy wasn't changed from default)
      assert has_element?(view, "button[phx-click=\"toggle_follow\"]")
      assert html =~ "Follow"
      assert has_element?(view, "button[phx-click=\"send_friend_request\"]")
      assert html =~ "Add Friend"
    end
  end

  describe "User Profile Stats Display" do
    test "shows followers, following, and friends count", %{
      conn: conn,
      public_user: public_user,
      viewer_user: viewer_user
    } do
      # Create another public user for following relationships
      another_public_user = AuthFixtures.user_fixture()
      {:ok, another_public_user} = Accounts.update_user(another_public_user, %{privacy: "public"})

      # Create some relationships to test counts
      {:ok, _} = Accounts.follow_user(viewer_user.id, public_user.id)
      {:ok, _} = Accounts.follow_user(public_user.id, another_public_user.id)
      {:ok, _} = Accounts.send_friend_request(viewer_user.id, public_user.id)
      {:ok, _} = Accounts.accept_friend_request(public_user.id, viewer_user.id)

      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{public_user.user_name}")

      # Should show all three stats with correct format
      # The template shows: <span class="font-bold">1</span> followers
      assert html =~ "1</span> followers"
      assert html =~ "1</span> following"
      assert html =~ "1</span> friends"

      # Should have the specific elements with spans
      assert has_element?(view, "span", "1")

      # Verify all three stats sections exist 
      assert html =~ "followers"
      assert html =~ "following"
      assert html =~ "friends"
    end
  end

  describe "Commitment Chart Privacy" do
    test "shows commitment chart for public users", %{
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
      assert has_element?(view, "h2", "Commitment Chart")
      refute html =~ "Chart is private"
    end

    test "shows commitment chart for own profile", %{conn: conn, viewer_user: viewer_user} do
      # Update user to private
      {:ok, private_viewer} = Accounts.update_user(viewer_user, %{privacy: "private"})

      {:ok, view, html} =
        conn
        |> log_in_user(private_viewer)
        |> live("/people/#{private_viewer.user_name}")

      # Should show the actual commitment chart even if private (own profile)
      assert html =~ "Commitment Chart"
      assert has_element?(view, "h2", "Commitment Chart")
      refute html =~ "Chart is private"
    end

    test "hides commitment chart for private users", %{
      conn: conn,
      private_user: private_user,
      viewer_user: viewer_user
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{private_user.user_name}")

      # Should show privacy message instead of chart
      assert html =~ "Commitment Chart"
      assert html =~ "Chart is private"
      # More flexible text matching
      assert html =~ "commitment chart is private"

      assert has_element?(
               view,
               "div[class*='bg-gray-100 p-4 rounded-lg border border-gray-200 text-center']"
             )

      refute has_element?(view, "h3", "Activity Chart")
    end

    test "hides commitment chart for friends-only users to non-friends", %{
      conn: conn,
      friends_only_user: friends_only_user,
      viewer_user: viewer_user
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{friends_only_user.user_name}")

      # Should show privacy message instead of chart
      assert html =~ "Commitment Chart"
      assert html =~ "Chart is private"
      assert html =~ "This user shares their commitment chart with friends only"

      assert has_element?(
               view,
               "div[class*='bg-gray-100 p-4 rounded-lg border border-gray-200 text-center']"
             )

      refute has_element?(view, "h3", "Activity Chart")
    end

    test "shows commitment chart for friends-only users to friends", %{
      conn: conn,
      friends_only_user: friends_only_user,
      viewer_user: viewer_user
    } do
      # Become friends first
      {:ok, _} = Accounts.send_friend_request(viewer_user.id, friends_only_user.id)
      {:ok, _} = Accounts.accept_friend_request(friends_only_user.id, viewer_user.id)

      {:ok, view, html} =
        conn
        |> log_in_user(viewer_user)
        |> live("/people/#{friends_only_user.user_name}")

      # Should show the actual commitment chart
      assert html =~ "Commitment Chart"
      assert has_element?(view, "h2", "Commitment Chart")
      refute html =~ "Chart is private"
    end

    test "hides commitment chart for unauthenticated users viewing private profiles", %{
      conn: conn,
      private_user: private_user
    } do
      # Verify the user is actually private
      assert private_user.privacy == "private"

      {:ok, view, html} = live(conn, "/people/#{private_user.user_name}")

      # Should show privacy message instead of chart
      assert html =~ "Commitment Chart"
      assert html =~ "Chart is private"
      # More flexible text matching
      assert html =~ "commitment chart is private"

      assert has_element?(
               view,
               "div[class*='bg-gray-100 p-4 rounded-lg border border-gray-200 text-center']"
             )

      refute has_element?(view, "h3", "Activity Chart")
    end

    test "shows commitment chart for unauthenticated users viewing public profiles", %{
      conn: conn,
      public_user: public_user
    } do
      {:ok, view, html} = live(conn, "/people/#{public_user.user_name}")

      # Should show the actual commitment chart
      assert html =~ "Commitment Chart"
      assert has_element?(view, "h2", "Commitment Chart")
      refute html =~ "Chart is private"
    end
  end
end
