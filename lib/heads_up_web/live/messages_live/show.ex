defmodule HeadsUpWeb.MessagesLive.Show do
  use HeadsUpWeb, :live_view
  alias HeadsUp.Messaging
  import HeadsUpWeb.Helpers.AvatarHelper

  def mount(%{"id" => conversation_id}, _session, socket) do
    current_user = socket.assigns.current_user

    case Messaging.get_conversation_for_user(conversation_id, current_user.id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Conversation not found")
         |> push_navigate(to: ~p"/messages")}

      conversation ->
        if connected?(socket) do
          Messaging.subscribe_to_conversation(conversation.id)
        end

        other_user = Messaging.get_other_user(conversation, current_user.id)
        messages = Messaging.list_messages(conversation.id)
        Messaging.mark_as_read(conversation.id, current_user.id)

        can_send = Messaging.can_message?(current_user.id, other_user.id)

        {:ok,
         socket
         |> assign(:conversation, conversation)
         |> assign(:other_user, other_user)
         |> assign(:messages, messages)
         |> assign(:can_send, can_send)
         |> assign(:message_form, to_form(%{"content" => ""}))
         |> assign(:page_title, "Chat with #{other_user.name || other_user.user_name}")}
    end
  end

  def handle_event("send_message", %{"content" => content}, socket) do
    content = String.trim(content)

    if content == "" do
      {:noreply, socket}
    else
      case Messaging.send_message(
             socket.assigns.conversation.id,
             socket.assigns.current_user.id,
             content
           ) do
        {:ok, _message} ->
          {:noreply,
           socket
           |> assign(:message_form, to_form(%{"content" => ""}))}

        {:error, :not_friends} ->
          {:noreply,
           socket
           |> assign(:can_send, false)
           |> put_flash(:error, "You must be friends to send messages")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to send message")}
      end
    end
  end

  def handle_info({:new_message, message}, socket) do
    current_user = socket.assigns.current_user

    # Mark as read if we're viewing the conversation
    if message.sender_id != current_user.id do
      Messaging.mark_as_read(socket.assigns.conversation.id, current_user.id)
    end

    {:noreply,
     socket
     |> assign(:messages, socket.assigns.messages ++ [message])}
  end

  def render(assigns) do
    ~H"""
    <style>
      @keyframes panelIn {
        from { opacity: 0; transform: translateY(15px); }
        to { opacity: 1; transform: translateY(0); }
      }
    </style>

    <div class="flex flex-col h-full" style="animation: panelIn 0.4s ease both;">
      <%!-- Chat Header --%>
      <div class="flex items-center gap-4 px-5 sm:px-8 py-4 bg-t66-card border-b border-white/[0.06]">
        <.link
          navigate={~p"/messages"}
          class="inline-flex items-center justify-center w-10 h-10 rounded-xl bg-white/[0.04] border border-white/[0.06] text-[#8a8680] hover:text-[#f0ece6] hover:border-white/[0.12] transition-colors"
        >
          <.icon name="hero-arrow-left" class="w-5 h-5" />
        </.link>

        <.link navigate={~p"/people/#{@other_user.user_name}"} class="flex items-center gap-3 group">
          <HeadsUpWeb.Components.UI.Avatar.avatar
            name={@other_user.name || @other_user.user_name || "U"}
            src={get_user_avatar(@other_user)}
            size={:md}
            rounded={:xl}
          />
          <div>
            <h2 class="text-sm font-bold text-[#f0ece6] group-hover:text-t66-accent transition-colors">
              {@other_user.name || @other_user.user_name}
            </h2>
            <p class="text-xs text-t66-text-muted">@{@other_user.user_name}</p>
          </div>
        </.link>
      </div>

      <%!-- Messages Area --%>
      <div
        id="messages-container"
        class="flex-1 overflow-y-auto p-4 sm:p-6 space-y-3 bg-[#0a0a0a]"
        phx-hook="ScrollBottom"
      >
        <%= if Enum.empty?(@messages) do %>
          <div class="flex flex-col items-center justify-center h-full text-center">
            <div class="w-14 h-14 rounded-xl bg-[rgba(255,77,0,0.15)] flex items-center justify-center mb-4">
              <.icon name="hero-chat-bubble-left-right" class="w-7 h-7 text-t66-accent" />
            </div>
            <h3 class="text-lg font-bold text-[#f0ece6] mb-2">Start the conversation</h3>
            <p class="text-t66-text-muted text-sm max-w-sm">
              Send a message to {@other_user.name || @other_user.user_name}
            </p>
          </div>
        <% else %>
          <%= for message <- @messages do %>
            <div class={[
              "flex",
              if(message.sender_id == @current_user.id, do: "justify-end", else: "justify-start")
            ]}>
              <div class={[
                "max-w-[75%] sm:max-w-[60%] px-4 py-3 rounded-2xl",
                if(message.sender_id == @current_user.id,
                  do: "bg-t66-accent text-white rounded-br-md",
                  else: "bg-t66-card border border-white/[0.06] text-[#f0ece6] rounded-bl-md"
                )
              ]}>
                <p class="text-sm whitespace-pre-wrap break-words">{message.content}</p>
                <p class={[
                  "text-[10px] mt-1",
                  if(message.sender_id == @current_user.id,
                    do: "text-white/60",
                    else: "text-t66-text-muted"
                  )
                ]}>
                  {format_message_time(message.inserted_at)}
                </p>
              </div>
            </div>
          <% end %>
        <% end %>
      </div>

      <%!-- Message Input --%>
      <div class="px-4 sm:px-6 py-4 bg-t66-card border-t border-white/[0.06]">
        <%= if @can_send do %>
          <.form for={@message_form} phx-submit="send_message" class="flex items-end gap-3">
            <div class="flex-1">
              <textarea
                name="content"
                rows="1"
                placeholder="Type a message..."
                class="w-full px-4 py-3 bg-[#0f0f0f] border border-white/[0.08] rounded-xl text-[#f0ece6] placeholder-[#5a5754] text-sm outline-none transition-all focus:border-[rgba(255,77,0,0.4)] focus:shadow-[0_0_0_3px_rgba(255,77,0,0.08)] resize-none"
                phx-hook="AutoResize"
                id="message-input"
              ></textarea>
            </div>
            <button
              type="submit"
              class="inline-flex items-center justify-center w-12 h-12 rounded-xl bg-t66-accent text-white hover:bg-[#e64400] transition-all shadow-[0_0_20px_rgba(255,77,0,0.2)] hover:shadow-[0_0_30px_rgba(255,77,0,0.35)] hover:-translate-y-0.5 flex-shrink-0"
            >
              <.icon name="hero-paper-airplane" class="w-5 h-5" />
            </button>
          </.form>
        <% else %>
          <div class="text-center py-3 px-4 bg-[#0f0f0f] border border-white/[0.08] rounded-xl">
            <p class="text-t66-text-muted text-sm font-medium">
              <.icon name="hero-lock-closed" class="w-4 h-4 inline" />
              You must be friends to send messages
            </p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp format_message_time(datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "Just now"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> Calendar.strftime(datetime, "%I:%M %p")
      true -> Calendar.strftime(datetime, "%b %d, %I:%M %p")
    end
  end
end
