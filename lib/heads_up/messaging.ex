defmodule HeadsUp.Messaging do
  alias HeadsUp.{Repo, Conversation, Message, Accounts}
  import Ecto.Query

  @doc """
  Checks if two users can message each other (must be friends).
  """
  def can_message?(user1_id, user2_id) do
    Accounts.are_friends?(user1_id, user2_id)
  end

  @doc """
  Gets or creates a conversation between two users.
  User IDs are ordered so user1_id < user2_id for consistency.
  """
  def get_or_create_conversation(user_a_id, user_b_id) do
    {user1_id, user2_id} = order_ids(user_a_id, user_b_id)

    case Repo.get_by(Conversation, user1_id: user1_id, user2_id: user2_id) do
      nil ->
        %Conversation{}
        |> Conversation.changeset(%{user1_id: user1_id, user2_id: user2_id})
        |> Repo.insert()

      conversation ->
        {:ok, conversation}
    end
  end

  @doc """
  Gets a conversation by ID, preloading users.
  """
  def get_conversation(id) do
    Conversation
    |> Repo.get(id)
    |> Repo.preload([:user1, :user2])
  end

  @doc """
  Gets a conversation only if the user is a participant.
  """
  def get_conversation_for_user(conversation_id, user_id) do
    from(c in Conversation,
      where: c.id == ^conversation_id,
      where: c.user1_id == ^user_id or c.user2_id == ^user_id,
      preload: [:user1, :user2]
    )
    |> Repo.one()
  end

  @doc """
  Sends a message in a conversation. Validates that sender is a participant.
  """
  def send_message(conversation_id, sender_id, content) do
    conversation = get_conversation(conversation_id)

    cond do
      is_nil(conversation) ->
        {:error, :conversation_not_found}

      sender_id != conversation.user1_id and sender_id != conversation.user2_id ->
        {:error, :not_participant}

      not can_message?(conversation.user1_id, conversation.user2_id) ->
        {:error, :not_friends}

      true ->
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        Ecto.Multi.new()
        |> Ecto.Multi.insert(
          :message,
          Message.changeset(%Message{}, %{
            content: content,
            conversation_id: conversation_id,
            sender_id: sender_id
          })
        )
        |> Ecto.Multi.update(
          :conversation,
          Conversation.changeset(conversation, %{
            last_message_at: now
          })
        )
        |> Repo.transaction()
        |> case do
          {:ok, %{message: message}} ->
            message = Repo.preload(message, :sender)
            broadcast_message(conversation_id, message)
            {:ok, message}

          {:error, :message, changeset, _} ->
            {:error, changeset}
        end
    end
  end

  @doc """
  Sends a message to a user, creating a conversation if needed.
  """
  def send_message_to_user(sender_id, receiver_id, content) do
    if can_message?(sender_id, receiver_id) do
      case get_or_create_conversation(sender_id, receiver_id) do
        {:ok, conversation} ->
          send_message(conversation.id, sender_id, content)

        {:error, reason} ->
          {:error, reason}
      end
    else
      {:error, :not_friends}
    end
  end

  @doc """
  Lists all conversations for a user, ordered by last message.
  Includes the other user and the last message.
  """
  def list_conversations(user_id) do
    from(c in Conversation,
      where: c.user1_id == ^user_id or c.user2_id == ^user_id,
      order_by: [desc: coalesce(c.last_message_at, c.inserted_at)],
      preload: [:user1, :user2]
    )
    |> Repo.all()
    |> Enum.map(fn conv ->
      last_message = get_last_message(conv.id)
      unread = unread_count_for_conversation(conv.id, user_id)
      other_user = if conv.user1_id == user_id, do: conv.user2, else: conv.user1

      %{
        conversation: conv,
        other_user: other_user,
        last_message: last_message,
        unread_count: unread
      }
    end)
  end

  @doc """
  Gets the last message in a conversation.
  """
  def get_last_message(conversation_id) do
    from(m in Message,
      where: m.conversation_id == ^conversation_id,
      order_by: [desc: m.inserted_at],
      limit: 1,
      preload: [:sender]
    )
    |> Repo.one()
  end

  @doc """
  Lists messages in a conversation, ordered by time (oldest first).
  """
  def list_messages(conversation_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)

    from(m in Message,
      where: m.conversation_id == ^conversation_id,
      order_by: [asc: m.inserted_at],
      limit: ^limit,
      offset: ^offset,
      preload: [:sender]
    )
    |> Repo.all()
  end

  @doc """
  Marks all unread messages in a conversation as read for the given user.
  Only marks messages sent by the OTHER user as read.
  """
  def mark_as_read(conversation_id, user_id) do
    from(m in Message,
      where: m.conversation_id == ^conversation_id,
      where: m.sender_id != ^user_id,
      where: m.read == false
    )
    |> Repo.update_all(set: [read: true])
  end

  @doc """
  Counts unread messages for a specific conversation for a user.
  """
  def unread_count_for_conversation(conversation_id, user_id) do
    from(m in Message,
      where: m.conversation_id == ^conversation_id,
      where: m.sender_id != ^user_id,
      where: m.read == false
    )
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Total unread message count across all conversations for a user.
  """
  def total_unread_count(user_id) do
    from(m in Message,
      join: c in Conversation,
      on: m.conversation_id == c.id,
      where: c.user1_id == ^user_id or c.user2_id == ^user_id,
      where: m.sender_id != ^user_id,
      where: m.read == false
    )
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets the other user in a conversation.
  """
  def get_other_user(conversation, current_user_id) do
    if conversation.user1_id == current_user_id do
      conversation.user2
    else
      conversation.user1
    end
  end

  # PubSub

  defp broadcast_message(conversation_id, message) do
    Phoenix.PubSub.broadcast(
      HeadsUp.PubSub,
      "conversation:#{conversation_id}",
      {:new_message, message}
    )

    # Also broadcast to both users' message feeds for unread badge updates
    conversation = get_conversation(conversation_id)

    if conversation do
      Phoenix.PubSub.broadcast(
        HeadsUp.PubSub,
        "user_messages:#{conversation.user1_id}",
        {:message_received, conversation_id}
      )

      Phoenix.PubSub.broadcast(
        HeadsUp.PubSub,
        "user_messages:#{conversation.user2_id}",
        {:message_received, conversation_id}
      )
    end
  end

  def subscribe_to_conversation(conversation_id) do
    Phoenix.PubSub.subscribe(HeadsUp.PubSub, "conversation:#{conversation_id}")
  end

  def subscribe_to_user_messages(user_id) do
    Phoenix.PubSub.subscribe(HeadsUp.PubSub, "user_messages:#{user_id}")
  end

  # Helpers

  defp order_ids(a, b) when a < b, do: {a, b}
  defp order_ids(a, b), do: {b, a}
end
