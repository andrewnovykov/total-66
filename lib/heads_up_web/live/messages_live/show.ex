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
    <div class="flex flex-col h-full">
      <%!-- Chat Header --%>
      <div class="flex items-center gap-4 p-4 sm:p-6 bg-white border-b border-slate-100">
        <.link
          navigate={~p"/messages"}
          class="inline-flex items-center justify-center w-10 h-10 rounded-xl bg-slate-50 text-slate-600 hover:bg-slate-100 transition-colors"
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
            <h2 class="text-sm font-extrabold text-slate-900 group-hover:text-blue-600 transition-colors">
              {@other_user.name || @other_user.user_name}
            </h2>
            <p class="text-xs text-slate-500">@{@other_user.user_name}</p>
          </div>
        </.link>
      </div>

      <%!-- Messages Area --%>
      <div
        id="messages-container"
        class="flex-1 overflow-y-auto p-4 sm:p-6 space-y-4 bg-[#F0F4FF]"
        phx-hook="ScrollBottom"
      >
        <%= if Enum.empty?(@messages) do %>
          <div class="flex flex-col items-center justify-center h-full text-center">
            <div class="w-16 h-16 rounded-2xl bg-white flex items-center justify-center mb-4 shadow-sm">
              <.icon name="hero-chat-bubble-left-right" class="w-8 h-8 text-slate-400" />
            </div>
            <h3 class="text-lg font-extrabold text-slate-700 mb-2">Start the conversation</h3>
            <p class="text-slate-500 text-sm max-w-sm">
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
                "max-w-[75%] sm:max-w-[60%] px-4 py-3 rounded-2xl shadow-sm",
                if(message.sender_id == @current_user.id,
                  do: "bg-gradient-to-r from-blue-500 to-indigo-600 text-white rounded-br-md",
                  else: "bg-white text-slate-900 rounded-bl-md"
                )
              ]}>
                <p class="text-sm whitespace-pre-wrap break-words">{message.content}</p>
                <p class={[
                  "text-[10px] mt-1",
                  if(message.sender_id == @current_user.id,
                    do: "text-blue-200",
                    else: "text-slate-400"
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
      <div class="p-4 sm:p-6 bg-white border-t border-slate-100">
        <%= if @can_send do %>
          <.form for={@message_form} phx-submit="send_message" class="flex items-end gap-3">
            <div class="flex-1">
              <textarea
                name="content"
                rows="1"
                placeholder="Type a message..."
                class="w-full px-4 py-3 bg-slate-50 border-0 rounded-2xl focus:ring-2 focus:ring-blue-500 text-slate-900 placeholder:text-slate-400 resize-none text-sm"
                phx-hook="AutoResize"
                id="message-input"
              ></textarea>
            </div>
            <button
              type="submit"
              class="inline-flex items-center justify-center w-12 h-12 rounded-xl bg-gradient-to-r from-blue-500 to-indigo-600 text-white hover:scale-105 transition-transform shadow-lg shadow-blue-500/20 flex-shrink-0"
            >
              <.icon name="hero-paper-airplane" class="w-5 h-5" />
            </button>
          </.form>
        <% else %>
          <div class="text-center py-3 px-4 bg-slate-50 rounded-2xl">
            <p class="text-slate-500 text-sm font-medium">
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
