defmodule HeadsUpWeb.MessagesLive.Index do
  use HeadsUpWeb, :live_view
  alias HeadsUp.Messaging
  import HeadsUpWeb.Helpers.AvatarHelper

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    if connected?(socket) do
      Messaging.subscribe_to_user_messages(current_user.id)
    end

    conversations = Messaging.list_conversations(current_user.id)

    {:ok,
     socket
     |> assign(:conversations, conversations)
     |> assign(:page_title, "Messages")}
  end

  def handle_info({:message_received, _conversation_id}, socket) do
    conversations = Messaging.list_conversations(socket.assigns.current_user.id)
    {:noreply, assign(socket, :conversations, conversations)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex gap-0 h-full">
      <div class="flex-grow min-w-0 p-5 sm:p-8 lg:p-10 overflow-y-auto custom-scrollbar">
        <%!-- Hero Banner --%>
        <div class="relative overflow-hidden bg-gradient-to-r from-blue-600 to-indigo-600 rounded-[40px] shadow-lg p-8 sm:p-10 lg:p-12 mb-8">
          <div class="relative z-10">
            <span class="inline-block px-4 py-1.5 bg-blue-500/50 text-blue-100 text-xs font-bold uppercase tracking-wider rounded-full mb-4">
              Chat
            </span>
            <h1 class="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-white mb-3">
              Messages
            </h1>
            <p class="text-blue-100 text-lg">Chat with your friends</p>
          </div>
          <div class="absolute top-6 right-6 opacity-10">
            <.icon name="hero-chat-bubble-left-right" class="w-32 h-32 text-white" />
          </div>
        </div>

        <%!-- Conversations List --%>
        <div class="bg-white rounded-[32px] shadow-sm p-6 sm:p-8">
          <h2 class="text-xl font-extrabold text-slate-900 flex items-center gap-2 mb-6">
            <.icon name="hero-chat-bubble-left-right" class="w-5 h-5 text-blue-600" /> Conversations
          </h2>

          <%= if Enum.empty?(@conversations) do %>
            <div class="text-center py-12">
              <div class="w-16 h-16 rounded-2xl bg-slate-50 flex items-center justify-center mx-auto mb-4">
                <.icon name="hero-chat-bubble-left-right" class="w-8 h-8 text-slate-400" />
              </div>
              <h3 class="text-lg font-extrabold text-slate-900 mb-2">No messages yet</h3>
              <p class="text-slate-500 text-sm max-w-sm mx-auto">
                Visit a friend's profile and tap the Message button to start chatting.
              </p>
            </div>
          <% else %>
            <div class="space-y-2">
              <%= for conv <- @conversations do %>
                <.link
                  navigate={~p"/messages/#{conv.conversation.id}"}
                  class="flex items-center gap-4 p-4 rounded-2xl hover:bg-slate-50 transition-colors group"
                >
                  <div class="relative flex-shrink-0">
                    <HeadsUpWeb.Components.UI.Avatar.avatar
                      name={conv.other_user.name || conv.other_user.user_name || "U"}
                      src={get_user_avatar(conv.other_user)}
                      size={:lg}
                      rounded={:xl}
                    />
                    <%= if conv.unread_count > 0 do %>
                      <div class="absolute -top-1 -right-1 w-5 h-5 bg-blue-600 rounded-full flex items-center justify-center">
                        <span class="text-[10px] font-bold text-white">{conv.unread_count}</span>
                      </div>
                    <% end %>
                  </div>

                  <div class="flex-1 min-w-0">
                    <div class="flex items-center justify-between mb-1">
                      <h3 class={[
                        "text-sm font-extrabold truncate group-hover:text-blue-600 transition-colors",
                        if(conv.unread_count > 0, do: "text-slate-900", else: "text-slate-700")
                      ]}>
                        {conv.other_user.name || conv.other_user.user_name}
                      </h3>
                      <%= if conv.last_message do %>
                        <span class="text-xs text-slate-400 flex-shrink-0 ml-2">
                          {format_time(conv.last_message.inserted_at)}
                        </span>
                      <% end %>
                    </div>
                    <p class={[
                      "text-sm truncate",
                      if(conv.unread_count > 0,
                        do: "text-slate-700 font-medium",
                        else: "text-slate-500"
                      )
                    ]}>
                      <%= if conv.last_message do %>
                        <%= if conv.last_message.sender_id == @current_user.id do %>
                          <span class="text-slate-400">You: </span>
                        <% end %>
                        {conv.last_message.content}
                      <% else %>
                        No messages yet
                      <% end %>
                    </p>
                  </div>

                  <.icon name="hero-chevron-right" class="w-4 h-4 text-slate-400 flex-shrink-0" />
                </.link>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp format_time(datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "now"
      diff < 3600 -> "#{div(diff, 60)}m"
      diff < 86400 -> "#{div(diff, 3600)}h"
      diff < 604_800 -> "#{div(diff, 86400)}d"
      true -> Calendar.strftime(datetime, "%b %d")
    end
  end
end
