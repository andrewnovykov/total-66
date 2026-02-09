defmodule HeadsUp.MessagingTest do
  use HeadsUp.DataCase
  alias HeadsUp.{Messaging, Accounts}
  import HeadsUp.AuthFixtures

  defp make_friends(user1, user2) do
    {:ok, _} = Accounts.send_friend_request(user1.id, user2.id)
    {:ok, _} = Accounts.accept_friend_request(user2.id, user1.id)
  end

  describe "can_message?/2" do
    test "returns true when users are friends" do
      user1 = user_fixture()
      user2 = user_fixture()
      make_friends(user1, user2)

      assert Messaging.can_message?(user1.id, user2.id)
    end

    test "returns false when users are not friends" do
      user1 = user_fixture()
      user2 = user_fixture()

      refute Messaging.can_message?(user1.id, user2.id)
    end
  end

  describe "get_or_create_conversation/2" do
    test "creates a new conversation between two users" do
      user1 = user_fixture()
      user2 = user_fixture()

      assert {:ok, conversation} = Messaging.get_or_create_conversation(user1.id, user2.id)
      assert conversation.user1_id == min(user1.id, user2.id)
      assert conversation.user2_id == max(user1.id, user2.id)
    end

    test "returns existing conversation if one already exists" do
      user1 = user_fixture()
      user2 = user_fixture()

      {:ok, conv1} = Messaging.get_or_create_conversation(user1.id, user2.id)
      {:ok, conv2} = Messaging.get_or_create_conversation(user1.id, user2.id)

      assert conv1.id == conv2.id
    end

    test "orders user IDs consistently regardless of argument order" do
      user1 = user_fixture()
      user2 = user_fixture()

      {:ok, conv1} = Messaging.get_or_create_conversation(user1.id, user2.id)
      {:ok, conv2} = Messaging.get_or_create_conversation(user2.id, user1.id)

      assert conv1.id == conv2.id
    end
  end

  describe "send_message/3" do
    test "sends a message in a conversation between friends" do
      user1 = user_fixture()
      user2 = user_fixture()
      make_friends(user1, user2)

      {:ok, conversation} = Messaging.get_or_create_conversation(user1.id, user2.id)
      assert {:ok, message} = Messaging.send_message(conversation.id, user1.id, "Hello!")

      assert message.content == "Hello!"
      assert message.sender_id == user1.id
      assert message.conversation_id == conversation.id
      assert message.read == false
    end

    test "updates conversation last_message_at" do
      user1 = user_fixture()
      user2 = user_fixture()
      make_friends(user1, user2)

      {:ok, conversation} = Messaging.get_or_create_conversation(user1.id, user2.id)
      assert is_nil(conversation.last_message_at)

      {:ok, _message} = Messaging.send_message(conversation.id, user1.id, "Hello!")
      updated = Messaging.get_conversation(conversation.id)
      assert updated.last_message_at != nil
    end

    test "returns error when users are not friends" do
      user1 = user_fixture()
      user2 = user_fixture()

      {:ok, conversation} = Messaging.get_or_create_conversation(user1.id, user2.id)
      assert {:error, :not_friends} = Messaging.send_message(conversation.id, user1.id, "Hello!")
    end

    test "returns error when sender is not a participant" do
      user1 = user_fixture()
      user2 = user_fixture()
      user3 = user_fixture()
      make_friends(user1, user2)

      {:ok, conversation} = Messaging.get_or_create_conversation(user1.id, user2.id)

      assert {:error, :not_participant} =
               Messaging.send_message(conversation.id, user3.id, "Hello!")
    end

    test "returns error for non-existent conversation" do
      user1 = user_fixture()

      assert {:error, :conversation_not_found} =
               Messaging.send_message(999_999, user1.id, "Hello!")
    end
  end

  describe "send_message_to_user/3" do
    test "creates conversation and sends message to a friend" do
      user1 = user_fixture()
      user2 = user_fixture()
      make_friends(user1, user2)

      assert {:ok, message} = Messaging.send_message_to_user(user1.id, user2.id, "Hi friend!")
      assert message.content == "Hi friend!"
    end

    test "returns error when not friends" do
      user1 = user_fixture()
      user2 = user_fixture()

      assert {:error, :not_friends} = Messaging.send_message_to_user(user1.id, user2.id, "Hi!")
    end
  end

  describe "list_conversations/1" do
    test "lists conversations for a user ordered by last message" do
      user1 = user_fixture()
      user2 = user_fixture()
      user3 = user_fixture()
      make_friends(user1, user2)
      make_friends(user1, user3)

      {:ok, _} = Messaging.send_message_to_user(user1.id, user2.id, "Hello user2")
      Process.sleep(1000)
      {:ok, _} = Messaging.send_message_to_user(user1.id, user3.id, "Hello user3")

      conversations = Messaging.list_conversations(user1.id)
      assert length(conversations) == 2

      # Most recent first
      [first, second] = conversations
      assert first.other_user.id == user3.id
      assert second.other_user.id == user2.id
    end

    test "returns empty list when no conversations" do
      user = user_fixture()
      assert Messaging.list_conversations(user.id) == []
    end

    test "includes unread count" do
      user1 = user_fixture()
      user2 = user_fixture()
      make_friends(user1, user2)

      {:ok, _} = Messaging.send_message_to_user(user1.id, user2.id, "Hello!")
      {:ok, _} = Messaging.send_message_to_user(user1.id, user2.id, "Another!")

      conversations = Messaging.list_conversations(user2.id)
      assert length(conversations) == 1
      [conv] = conversations
      assert conv.unread_count == 2
    end
  end

  describe "list_messages/1" do
    test "lists messages in a conversation ordered by time" do
      user1 = user_fixture()
      user2 = user_fixture()
      make_friends(user1, user2)

      {:ok, conversation} = Messaging.get_or_create_conversation(user1.id, user2.id)
      {:ok, _} = Messaging.send_message(conversation.id, user1.id, "First")
      {:ok, _} = Messaging.send_message(conversation.id, user2.id, "Second")
      {:ok, _} = Messaging.send_message(conversation.id, user1.id, "Third")

      messages = Messaging.list_messages(conversation.id)
      assert length(messages) == 3
      assert Enum.map(messages, & &1.content) == ["First", "Second", "Third"]
    end
  end

  describe "mark_as_read/2" do
    test "marks messages from other user as read" do
      user1 = user_fixture()
      user2 = user_fixture()
      make_friends(user1, user2)

      {:ok, conversation} = Messaging.get_or_create_conversation(user1.id, user2.id)
      {:ok, _} = Messaging.send_message(conversation.id, user1.id, "Read this!")
      {:ok, _} = Messaging.send_message(conversation.id, user1.id, "And this!")

      assert Messaging.unread_count_for_conversation(conversation.id, user2.id) == 2

      Messaging.mark_as_read(conversation.id, user2.id)

      assert Messaging.unread_count_for_conversation(conversation.id, user2.id) == 0
    end

    test "does not mark own messages as read" do
      user1 = user_fixture()
      user2 = user_fixture()
      make_friends(user1, user2)

      {:ok, conversation} = Messaging.get_or_create_conversation(user1.id, user2.id)
      {:ok, _} = Messaging.send_message(conversation.id, user1.id, "My message")

      # user1 should have 0 unread (they sent it)
      assert Messaging.unread_count_for_conversation(conversation.id, user1.id) == 0
    end
  end

  describe "total_unread_count/1" do
    test "counts total unread across all conversations" do
      user1 = user_fixture()
      user2 = user_fixture()
      user3 = user_fixture()
      make_friends(user1, user2)
      make_friends(user1, user3)

      {:ok, _} = Messaging.send_message_to_user(user2.id, user1.id, "From user2")
      {:ok, _} = Messaging.send_message_to_user(user3.id, user1.id, "From user3")
      {:ok, _} = Messaging.send_message_to_user(user3.id, user1.id, "Another from user3")

      assert Messaging.total_unread_count(user1.id) == 3
    end
  end

  describe "get_other_user/2" do
    test "returns the other user in a conversation" do
      user1 = user_fixture()
      user2 = user_fixture()

      {:ok, conversation} = Messaging.get_or_create_conversation(user1.id, user2.id)
      conversation = Messaging.get_conversation(conversation.id)

      other = Messaging.get_other_user(conversation, user1.id)
      assert other.id == user2.id

      other2 = Messaging.get_other_user(conversation, user2.id)
      assert other2.id == user1.id
    end
  end
end
