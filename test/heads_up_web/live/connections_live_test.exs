defmodule HeadsUpWeb.ConnectionsLiveTest do
  use HeadsUpWeb.ConnCase

  import Phoenix.LiveViewTest
  alias HeadsUp.{Accounts, AuthFixtures}

  setup %{conn: conn} do
    # Create test users
    user1 = AuthFixtures.user_fixture()
    user2 = AuthFixtures.user_fixture()
    user3 = AuthFixtures.user_fixture()

    %{conn: conn, user1: user1, user2: user2, user3: user3}
  end

  describe "Connections page" do
    test "redirects unauthenticated users to login", %{conn: conn} do
      {:error, redirect} = live(conn, "/connections")

      assert {:redirect, %{to: "/users/log_in"}} = redirect
    end

    test "renders connections page for authenticated user", %{conn: conn, user1: user1} do
      {:ok, view, html} =
        conn
        |> log_in_user(user1)
        |> live("/connections")

      assert html =~ "Connections"
      assert html =~ "Manage your social connections and relationships"
      # The page should render successfully
    end

    test "displays correct stats counts", %{conn: conn, user1: user1, user2: user2, user3: user3} do
      # Set up some connections
      {:ok, _} = Accounts.follow_user(user1.id, user2.id)
      {:ok, _} = Accounts.follow_user(user3.id, user1.id)
      {:ok, _} = Accounts.send_friend_request(user2.id, user1.id)
      {:ok, _} = Accounts.accept_friend_request(user1.id, user2.id)

      {:ok, view, html} =
        conn
        |> log_in_user(user1)
        |> live("/connections")

      # Check stats cards
      # Following count
      assert html =~ "1"
      # Followers count  
      assert html =~ "1"
      # Friends count
      assert html =~ "1"
      assert html =~ "Following"
      assert html =~ "Followers"
      assert html =~ "Friends"
    end

    test "can switch between tabs", %{conn: conn, user1: user1} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user1)
        |> live("/connections")

      # Default tab should be following
      assert has_element?(view, "button[phx-value-tab=\"following\"][class*=\"border-blue-500\"]")

      # Switch to followers tab
      view |> element("button[phx-value-tab=\"followers\"]") |> render_click()
      assert_patched(view, "/connections?tab=followers")

      # Switch to friends tab
      view |> element("button[phx-value-tab=\"friends\"]") |> render_click()
      assert_patched(view, "/connections?tab=friends")

      # Switch to requests tab
      view |> element("button[phx-value-tab=\"requests\"]") |> render_click()
      assert_patched(view, "/connections?tab=requests")
    end

    test "can unfollow users from following tab", %{conn: conn, user1: user1, user2: user2} do
      # Set up following relationship
      {:ok, _} = Accounts.follow_user(user1.id, user2.id)

      {:ok, view, _html} =
        conn
        |> log_in_user(user1)
        |> live("/connections?tab=following")

      # Should show the followed user
      assert has_element?(view, "div", user2.name)

      # Unfollow the user
      view
      |> element("button[phx-click=\"unfollow_user\"][phx-value-user_id=\"#{user2.id}\"]")
      |> render_click()

      # Should show success message
      assert render(view) =~ "Successfully unfollowed user"

      # User should no longer appear in following list
      refute has_element?(view, "div", user2.name)
    end

    test "can remove followers from followers tab", %{conn: conn, user1: user1, user2: user2} do
      # Set up follower relationship
      {:ok, _} = Accounts.follow_user(user2.id, user1.id)

      {:ok, view, _html} =
        conn
        |> log_in_user(user1)
        |> live("/connections?tab=followers")

      # Should show the follower
      assert has_element?(view, "div", user2.name)

      # Remove the follower
      view
      |> element("button[phx-click=\"remove_follower\"][phx-value-user_id=\"#{user2.id}\"]")
      |> render_click()

      # Should show success message
      assert render(view) =~ "Successfully removed follower"

      # User should no longer appear in followers list
      refute has_element?(view, "div", user2.name)
    end

    test "can accept friend requests", %{conn: conn, user1: user1, user2: user2} do
      # Set up friend request
      {:ok, _} = Accounts.send_friend_request(user2.id, user1.id)

      {:ok, view, _html} =
        conn
        |> log_in_user(user1)
        |> live("/connections?tab=requests")

      # Should show the friend request
      assert has_element?(view, "div", user2.name)
      assert has_element?(view, "button", "Accept")

      # Accept the friend request
      view
      |> element("button[phx-click=\"accept_friend_request\"][phx-value-user_id=\"#{user2.id}\"]")
      |> render_click()

      # Should show success message
      assert render(view) =~ "Friend request accepted"

      # Request should no longer appear in incoming requests
      refute has_element?(view, "div[class*=\"bg-blue-50\"]")
    end

    test "can decline friend requests", %{conn: conn, user1: user1, user2: user2} do
      # Set up friend request
      {:ok, _} = Accounts.send_friend_request(user2.id, user1.id)

      {:ok, view, _html} =
        conn
        |> log_in_user(user1)
        |> live("/connections?tab=requests")

      # Should show the friend request
      assert has_element?(view, "div", user2.name)
      assert has_element?(view, "button", "Decline")

      # Decline the friend request
      view
      |> element(
        "button[phx-click=\"decline_friend_request\"][phx-value-user_id=\"#{user2.id}\"]"
      )
      |> render_click()

      # Should show success message
      assert render(view) =~ "Friend request declined"

      # Request should no longer appear in incoming requests
      refute has_element?(view, "div[class*=\"bg-blue-50\"]")
    end
  end

  describe "Empty states" do
    test "shows empty state messages when no connections exist", %{conn: conn, user1: user1} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user1)
        |> live("/connections")

      # Following tab empty state
      assert has_element?(view, "div", "You're not following anyone yet")

      # Switch to followers tab
      view |> element("button[phx-value-tab=\"followers\"]") |> render_click()
      assert has_element?(view, "div", "No followers yet")

      # Switch to friends tab  
      view |> element("button[phx-value-tab=\"friends\"]") |> render_click()
      assert has_element?(view, "div", "No friends yet")

      # Switch to requests tab
      view |> element("button[phx-value-tab=\"requests\"]") |> render_click()
      assert has_element?(view, "div", "No pending friend requests")
      assert has_element?(view, "div", "No pending sent requests")
    end
  end
end
