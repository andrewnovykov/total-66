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
    <style>
      @keyframes panelIn {
        from { opacity: 0; transform: translateY(15px); }
        to { opacity: 1; transform: translateY(0); }
      }
    </style>

    <div style="animation: panelIn 0.4s ease both;">
      <div class="max-w-3xl mx-auto px-5 sm:px-8 py-8 sm:py-12">
        <%!-- Panel Header --%>
        <div class="mb-8">
          <h1 class="font-['Bebas_Neue'] text-[clamp(2rem,4vw,2.6rem)] tracking-[3px] text-[#f0ece6] leading-none">
            Messages
          </h1>
          <p class="text-t66-text-muted text-[0.9rem] mt-1.5">
            Your conversations
          </p>
        </div>

        <%!-- Conversations List --%>
        <div class="bg-t66-card border border-white/[0.06] rounded-2xl overflow-hidden">
          <div class="flex items-center gap-3 px-6 pt-6 pb-4">
            <div class="w-10 h-10 bg-[rgba(255,77,0,0.15)] rounded-xl flex items-center justify-center">
              <.icon name="hero-chat-bubble-left-right" class="w-5 h-5 text-t66-accent" />
            </div>
            <div>
              <h2 class="font-['Bebas_Neue'] text-[1.3rem] tracking-[2px] text-[#f0ece6]">
                Conversations
              </h2>
              <p class="text-sm text-t66-text-muted">
                {length(@conversations)} total
              </p>
            </div>
          </div>

          <%= if Enum.empty?(@conversations) do %>
            <div class="text-center py-12 px-6">
              <div class="w-14 h-14 rounded-xl bg-[rgba(255,77,0,0.15)] flex items-center justify-center mx-auto mb-4">
                <.icon name="hero-chat-bubble-left-right" class="w-7 h-7 text-t66-accent" />
              </div>
              <h3 class="text-lg font-bold text-[#f0ece6] mb-2">No messages yet</h3>
              <p class="text-t66-text-muted text-sm max-w-sm mx-auto">
                Visit a friend's profile and tap the Message button to start chatting.
              </p>
              <.link
                navigate={~p"/people"}
                class="inline-flex items-center gap-2 mt-6 bg-t66-accent text-white px-6 py-3 rounded-xl font-bold text-sm hover:-translate-y-0.5 transition-transform shadow-[0_0_30px_rgba(255,77,0,0.2)]"
              >
                <.icon name="hero-users" class="w-4 h-4" /> Find People
              </.link>
            </div>
          <% else %>
            <div class="flex flex-col gap-1 px-2 pb-2">
              <%= for conv <- @conversations do %>
                <.link
                  navigate={~p"/messages/#{conv.conversation.id}"}
                  class={[
                    "flex items-center gap-3.5 px-4 py-4 rounded-xl transition-colors group",
                    if(conv.unread_count > 0,
                      do: "border-l-[3px] border-t66-accent bg-[rgba(255,77,0,0.04)]",
                      else: "hover:bg-white/[0.03]"
                    )
                  ]}
                >
                  <div class="relative flex-shrink-0">
                    <HeadsUpWeb.Components.UI.Avatar.avatar
                      name={conv.other_user.name || conv.other_user.user_name || "U"}
                      src={get_user_avatar(conv.other_user)}
                      size={:lg}
                      rounded={:xl}
                    />
                    <%= if conv.unread_count > 0 do %>
                      <div class="absolute -top-1 -right-1 w-5 h-5 bg-t66-accent rounded-full flex items-center justify-center">
                        <span class="text-[10px] font-bold text-white">{conv.unread_count}</span>
                      </div>
                    <% end %>
                  </div>

                  <div class="flex-1 min-w-0">
                    <div class="flex items-center justify-between mb-0.5">
                      <h3 class={[
                        "text-[0.88rem] font-bold truncate group-hover:text-t66-accent transition-colors",
                        if(conv.unread_count > 0, do: "text-t66-accent", else: "text-[#f0ece6]")
                      ]}>
                        {conv.other_user.name || conv.other_user.user_name}
                      </h3>
                      <%= if conv.last_message do %>
                        <span class="text-[0.7rem] text-t66-text-muted flex-shrink-0 ml-2">
                          {format_time(conv.last_message.inserted_at)}
                        </span>
                      <% end %>
                    </div>
                    <p class={[
                      "text-[0.82rem] truncate",
                      if(conv.unread_count > 0,
                        do: "text-[#8a8680] font-medium",
                        else: "text-t66-text-muted"
                      )
                    ]}>
                      <%= if conv.last_message do %>
                        <%= if conv.last_message.sender_id == @current_user.id do %>
                          <span class="text-t66-text-muted">You: </span>
                        <% end %>
                        {conv.last_message.content}
                      <% else %>
                        No messages yet
                      <% end %>
                    </p>
                  </div>

                  <%= if conv.unread_count > 0 do %>
                    <div class="w-2.5 h-2.5 rounded-full bg-t66-accent flex-shrink-0"></div>
                  <% else %>
                    <.icon name="hero-chevron-right" class="w-4 h-4 text-t66-text-muted flex-shrink-0" />
                  <% end %>
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
