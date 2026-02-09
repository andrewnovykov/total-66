defmodule HeadsUpWeb.MessagesLiveTest do
  use HeadsUpWeb.ConnCase
  import Phoenix.LiveViewTest
  import HeadsUp.AuthFixtures
  alias HeadsUp.{Accounts, Messaging}

  defp make_friends(user1, user2) do
    {:ok, _} = Accounts.send_friend_request(user1.id, user2.id)
    {:ok, _} = Accounts.accept_friend_request(user2.id, user1.id)
  end

  describe "Messages Index" do
    setup :register_and_log_in_user

    test "renders messages page", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/messages")
      assert html =~ "Messages"
      assert html =~ "No messages yet"
      assert has_element?(view, "h1", "Messages")
    end

    test "shows conversations with friends", %{conn: conn, user: user} do
      friend = user_fixture(%{name: "Chat Friend"})
      make_friends(user, friend)
      {:ok, _} = Messaging.send_message_to_user(friend.id, user.id, "Hey there!")

      {:ok, _view, html} = live(conn, ~p"/messages")
      assert html =~ "Chat Friend"
      assert html =~ "Hey there!"
    end

    test "shows unread count badge", %{conn: conn, user: user} do
      friend = user_fixture()
      make_friends(user, friend)
      {:ok, _} = Messaging.send_message_to_user(friend.id, user.id, "Unread 1")
      {:ok, _} = Messaging.send_message_to_user(friend.id, user.id, "Unread 2")

      {:ok, _view, html} = live(conn, ~p"/messages")
      assert html =~ "2"
    end

    test "shows 'You:' prefix for own messages", %{conn: conn, user: user} do
      friend = user_fixture()
      make_friends(user, friend)
      {:ok, _} = Messaging.send_message_to_user(user.id, friend.id, "My message")

      {:ok, _view, html} = live(conn, ~p"/messages")
      assert html =~ "You:"
      assert html =~ "My message"
    end
  end

  describe "Messages Show" do
    setup :register_and_log_in_user

    test "renders conversation with a friend", %{conn: conn, user: user} do
      friend = user_fixture(%{name: "Best Friend", user_name: "bestfriend"})
      make_friends(user, friend)
      {:ok, conversation} = Messaging.get_or_create_conversation(user.id, friend.id)

      {:ok, _view, html} = live(conn, ~p"/messages/#{conversation.id}")
      assert html =~ "Best Friend"
      assert html =~ "@bestfriend"
      assert html =~ "Start the conversation"
    end

    test "shows existing messages", %{conn: conn, user: user} do
      friend = user_fixture()
      make_friends(user, friend)
      {:ok, conversation} = Messaging.get_or_create_conversation(user.id, friend.id)
      {:ok, _} = Messaging.send_message(conversation.id, user.id, "Hello friend!")
      {:ok, _} = Messaging.send_message(conversation.id, friend.id, "Hi back!")

      {:ok, _view, html} = live(conn, ~p"/messages/#{conversation.id}")
      assert html =~ "Hello friend!"
      assert html =~ "Hi back!"
    end

    test "can send a message", %{conn: conn, user: user} do
      friend = user_fixture()
      make_friends(user, friend)
      {:ok, conversation} = Messaging.get_or_create_conversation(user.id, friend.id)

      {:ok, view, _html} = live(conn, ~p"/messages/#{conversation.id}")

      view
      |> form("[phx-submit=send_message]", %{content: "New message!"})
      |> render_submit()

      # The message should appear via PubSub
      html = render(view)
      assert html =~ "New message!"
    end

    test "shows disabled input when not friends", %{conn: conn, user: user} do
      other = user_fixture()
      # Create conversation without being friends (e.g., friendship was removed)
      {:ok, conversation} = Messaging.get_or_create_conversation(user.id, other.id)

      {:ok, _view, html} = live(conn, ~p"/messages/#{conversation.id}")
      assert html =~ "You must be friends to send messages"
    end

    test "redirects when conversation not found", %{conn: conn} do
      assert {:error, {:live_redirect, %{to: "/messages"}}} =
               live(conn, ~p"/messages/999999")
    end

    test "redirects when user is not a participant", %{conn: conn} do
      user1 = user_fixture()
      user2 = user_fixture()
      {:ok, conversation} = Messaging.get_or_create_conversation(user1.id, user2.id)

      assert {:error, {:live_redirect, %{to: "/messages"}}} =
               live(conn, ~p"/messages/#{conversation.id}")
    end

    test "does not send empty messages", %{conn: conn, user: user} do
      friend = user_fixture()
      make_friends(user, friend)
      {:ok, conversation} = Messaging.get_or_create_conversation(user.id, friend.id)

      {:ok, view, _html} = live(conn, ~p"/messages/#{conversation.id}")

      view
      |> form("[phx-submit=send_message]", %{content: "   "})
      |> render_submit()

      messages = Messaging.list_messages(conversation.id)
      assert Enum.empty?(messages)
    end
  end

  describe "Message button on profile page" do
    setup :register_and_log_in_user

    test "shows disabled message button for non-friends", %{conn: conn} do
      _other = user_fixture(%{user_name: "notfriend", name: "Not Friend"})

      {:ok, _view, html} = live(conn, ~p"/people/notfriend")
      assert html =~ "Message"
      assert html =~ "disabled"
    end

    test "shows enabled message button for friends", %{conn: conn, user: user} do
      friend = user_fixture(%{user_name: "myfriend", name: "My Friend"})
      make_friends(user, friend)

      {:ok, view, html} = live(conn, ~p"/people/myfriend")
      assert html =~ "Message"

      # Click the message button - should navigate to conversation
      view
      |> element("button", "Message")
      |> render_click()

      {path, _flash} = assert_redirect(view)
      assert path =~ "/messages/"
    end
  end

  describe "requires authentication" do
    test "redirects to login when not authenticated for index", %{conn: conn} do
      result = get(conn, ~p"/messages")
      assert redirected_to(result) =~ "/users/log_in"
    end

    test "redirects to login when not authenticated for show", %{conn: conn} do
      result = get(conn, ~p"/messages/1")
      assert redirected_to(result) =~ "/users/log_in"
    end
  end
end
