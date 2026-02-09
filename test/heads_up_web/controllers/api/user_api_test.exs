defmodule HeadsUpWeb.Api.UserAPITest do
  use HeadsUpWeb.ConnCase

  alias HeadsUp.{Accounts, Users, Repo}

  setup %{conn: conn} do
    # Create test users with different privacy settings
    public_user = HeadsUp.AuthFixtures.user_fixture(%{privacy: "public"})
    private_user = HeadsUp.AuthFixtures.user_fixture(%{privacy: "private"})
    friends_only_user = HeadsUp.AuthFixtures.user_fixture(%{privacy: "friends_only"})

    # Update users with privacy settings
    {:ok, public_user} = Accounts.update_user(public_user, %{privacy: "public"})
    {:ok, private_user} = Accounts.update_user(private_user, %{privacy: "private"})
    {:ok, friends_only_user} = Accounts.update_user(friends_only_user, %{privacy: "friends_only"})

    %{
      conn: conn,
      public_user: public_user,
      private_user: private_user,
      friends_only_user: friends_only_user
    }
  end

  describe "User Follow System with Privacy" do
    test "users can follow public users", %{conn: conn, public_user: public_user} do
      follower = HeadsUp.AuthFixtures.user_fixture()

      conn =
        conn
        |> log_in_user(follower)
        |> post("/api/users/#{public_user.id}/follow")

      assert json_response(conn, 200)["message"] == "User followed successfully"
      assert Accounts.is_following?(follower.id, public_user.id)
    end

    test "users cannot follow private users", %{conn: conn, private_user: private_user} do
      follower = HeadsUp.AuthFixtures.user_fixture()

      conn =
        conn
        |> log_in_user(follower)
        |> post("/api/users/#{private_user.id}/follow")

      assert json_response(conn, 403)["error"]["message"] == "Cannot follow private user"
      refute Accounts.is_following?(follower.id, private_user.id)
    end

    test "users cannot follow friends_only users without being friends", %{
      conn: conn,
      friends_only_user: friends_only_user
    } do
      follower = HeadsUp.AuthFixtures.user_fixture()

      conn =
        conn
        |> log_in_user(follower)
        |> post("/api/users/#{friends_only_user.id}/follow")

      assert json_response(conn, 403)["error"]["message"] == "Must be friends to follow this user"
      refute Accounts.is_following?(follower.id, friends_only_user.id)
    end

    test "friends can follow friends_only users", %{
      conn: conn,
      friends_only_user: friends_only_user
    } do
      follower = HeadsUp.AuthFixtures.user_fixture()

      # First create friendship
      {:ok, _} = Accounts.send_friend_request(follower.id, friends_only_user.id)
      {:ok, _} = Accounts.accept_friend_request(friends_only_user.id, follower.id)

      # Now try to follow
      conn =
        conn
        |> log_in_user(follower)
        |> post("/api/users/#{friends_only_user.id}/follow")

      assert json_response(conn, 200)["message"] == "User followed successfully"
      assert Accounts.is_following?(follower.id, friends_only_user.id)
    end

    test "users cannot follow themselves", %{conn: conn, public_user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> post("/api/users/#{user.id}/follow")

      assert json_response(conn, 403)["error"]["message"] == "You cannot follow yourself"
    end

    test "users can unfollow users they follow", %{conn: conn, public_user: public_user} do
      follower = HeadsUp.AuthFixtures.user_fixture()

      # First follow
      {:ok, _} = Accounts.follow_user(follower.id, public_user.id)
      assert Accounts.is_following?(follower.id, public_user.id)

      # Then unfollow
      conn =
        conn
        |> log_in_user(follower)
        |> delete("/api/users/#{public_user.id}/follow")

      assert json_response(conn, 200)["message"] == "User unfollowed successfully"
      refute Accounts.is_following?(follower.id, public_user.id)
    end
  end

  describe "Friend Request System" do
    test "users can send friend requests", %{conn: conn, public_user: target_user} do
      requester = HeadsUp.AuthFixtures.user_fixture()

      conn =
        conn
        |> log_in_user(requester)
        |> post("/api/users/#{target_user.id}/friend-request")

      assert json_response(conn, 200)["message"] == "Friend request sent successfully"

      # Verify friend request exists
      requests = Accounts.list_friend_requests(target_user.id)
      assert length(requests) == 1
      assert List.first(requests).user_id == requester.id
    end

    test "users cannot send friend request to themselves", %{conn: conn, public_user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> post("/api/users/#{user.id}/friend-request")

      assert json_response(conn, 403)["error"]["message"] ==
               "You cannot send friend request to yourself"
    end

    test "users cannot send duplicate friend requests", %{conn: conn, public_user: target_user} do
      requester = HeadsUp.AuthFixtures.user_fixture()

      # Send first request
      {:ok, _} = Accounts.send_friend_request(requester.id, target_user.id)

      # Try to send duplicate
      conn =
        conn
        |> log_in_user(requester)
        |> post("/api/users/#{target_user.id}/friend-request")

      assert json_response(conn, 409)["error"]["message"] == "Friendship already exists"
    end

    test "users can accept friend requests", %{conn: conn, public_user: requester} do
      accepter = HeadsUp.AuthFixtures.user_fixture()

      # Send friend request
      {:ok, _} = Accounts.send_friend_request(requester.id, accepter.id)

      # Accept request
      conn =
        conn
        |> log_in_user(accepter)
        |> post("/api/friend-requests/#{requester.id}/accept")

      assert json_response(conn, 200)["message"] == "Friend request accepted"
      assert Accounts.are_friends?(requester.id, accepter.id)
    end

    test "users can decline friend requests", %{conn: conn, public_user: requester} do
      decliner = HeadsUp.AuthFixtures.user_fixture()

      # Send friend request
      {:ok, _} = Accounts.send_friend_request(requester.id, decliner.id)

      # Decline request
      conn =
        conn
        |> log_in_user(decliner)
        |> post("/api/friend-requests/#{requester.id}/decline")

      assert json_response(conn, 200)["message"] == "Friend request declined"
      refute Accounts.are_friends?(requester.id, decliner.id)
    end

    test "users can cancel friend requests they sent", %{conn: conn, public_user: target_user} do
      requester = HeadsUp.AuthFixtures.user_fixture()

      # Send friend request
      {:ok, _} = Accounts.send_friend_request(requester.id, target_user.id)

      # Cancel request
      conn =
        conn
        |> log_in_user(requester)
        |> delete("/api/friend-requests/#{target_user.id}")

      assert json_response(conn, 200)["message"] == "Friend request cancelled"

      # Verify request is gone
      requests = Accounts.list_friend_requests(target_user.id)
      assert length(requests) == 0
    end

    test "users cannot cancel friend requests they didn't send", %{
      conn: conn,
      public_user: requester
    } do
      other_user = HeadsUp.AuthFixtures.user_fixture()

      # Requester sends friend request to other_user
      {:ok, _} = Accounts.send_friend_request(requester.id, other_user.id)

      # Other user tries to cancel the request they received
      conn =
        conn
        |> log_in_user(other_user)
        |> delete("/api/friend-requests/#{requester.id}")

      assert json_response(conn, 404)["error"]["message"] == "Friend request not found"
    end

    test "users can remove friends", %{conn: conn, public_user: user1} do
      user2 = HeadsUp.AuthFixtures.user_fixture()

      # Create friendship
      {:ok, _} = Accounts.send_friend_request(user1.id, user2.id)
      {:ok, _} = Accounts.accept_friend_request(user2.id, user1.id)
      assert Accounts.are_friends?(user1.id, user2.id)

      # Remove friend
      conn =
        conn
        |> log_in_user(user1)
        |> delete("/api/friends/#{user2.id}")

      assert json_response(conn, 200)["message"] == "Friend removed successfully"
      refute Accounts.are_friends?(user1.id, user2.id)
    end

    test "users can list their incoming friend requests", %{conn: conn} do
      receiver = HeadsUp.AuthFixtures.user_fixture()
      sender1 = HeadsUp.AuthFixtures.user_fixture()
      sender2 = HeadsUp.AuthFixtures.user_fixture()

      # Send friend requests
      {:ok, _} = Accounts.send_friend_request(sender1.id, receiver.id)
      {:ok, _} = Accounts.send_friend_request(sender2.id, receiver.id)

      conn =
        conn
        |> log_in_user(receiver)
        |> get("/api/friend-requests")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2

      # Check that both senders are in the list
      sender_ids = Enum.map(response["data"], & &1["from"]["id"])
      assert sender1.id in sender_ids
      assert sender2.id in sender_ids
    end

    test "users can list their friends", %{conn: conn} do
      user = HeadsUp.AuthFixtures.user_fixture()
      friend1 = HeadsUp.AuthFixtures.user_fixture()
      friend2 = HeadsUp.AuthFixtures.user_fixture()

      # Create friendships
      {:ok, _} = Accounts.send_friend_request(user.id, friend1.id)
      {:ok, _} = Accounts.accept_friend_request(friend1.id, user.id)

      {:ok, _} = Accounts.send_friend_request(friend2.id, user.id)
      {:ok, _} = Accounts.accept_friend_request(user.id, friend2.id)

      conn =
        conn
        |> log_in_user(user)
        |> get("/api/friends")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2

      # Check that both friends are in the list
      friend_ids = Enum.map(response["data"], & &1["id"])
      assert friend1.id in friend_ids
      assert friend2.id in friend_ids
    end
  end

  describe "Authentication Requirements" do
    test "unauthenticated users cannot follow", %{conn: conn, public_user: user} do
      conn = post(conn, "/api/users/#{user.id}/follow")
      assert json_response(conn, 401)["error"]["message"] == "Authentication required"
    end

    test "unauthenticated users cannot send friend requests", %{conn: conn, public_user: user} do
      conn = post(conn, "/api/users/#{user.id}/friend-request")
      assert json_response(conn, 401)["error"]["message"] == "Authentication required"
    end

    test "unauthenticated users cannot list friend requests", %{conn: conn} do
      conn = get(conn, "/api/friend-requests")
      assert json_response(conn, 401)["error"]["message"] == "Authentication required"
    end

    test "unauthenticated users cannot list friends", %{conn: conn} do
      conn = get(conn, "/api/friends")
      assert json_response(conn, 401)["error"]["message"] == "Authentication required"
    end
  end
end
