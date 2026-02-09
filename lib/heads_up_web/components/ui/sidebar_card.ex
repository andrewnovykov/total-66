defmodule HeadsUpWeb.Components.UI.SidebarCard do
  use Phoenix.Component
  alias HeadsUpWeb.Components.UI.Avatar

  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :image, :string, default: nil
  attr :avatar_name, :string, default: nil
  attr :navigate, :string, default: nil
  slot :action

  def sidebar_card(assigns) do
    ~H"""
    <.link
      :if={@navigate}
      navigate={@navigate}
      class="flex items-start gap-3 p-3 rounded-2xl hover:bg-gray-50 transition-colors"
    >
      <Avatar.avatar :if={@avatar_name} name={@avatar_name} src={@image} size={:sm} />
      <img
        :if={@image && !@avatar_name}
        src={@image}
        alt={@title}
        class="w-10 h-10 rounded-xl object-cover shrink-0"
      />
      <div class="flex-1 min-w-0">
        <p class="text-sm font-semibold text-gray-900 truncate">{@title}</p>
        <p :if={@subtitle} class="text-xs text-gray-500 truncate mt-0.5">{@subtitle}</p>
      </div>
      {render_slot(@action)}
    </.link>
    <div :if={!@navigate} class="flex items-start gap-3 p-3 rounded-2xl">
      <Avatar.avatar :if={@avatar_name} name={@avatar_name} src={@image} size={:sm} />
      <img
        :if={@image && !@avatar_name}
        src={@image}
        alt={@title}
        class="w-10 h-10 rounded-xl object-cover shrink-0"
      />
      <div class="flex-1 min-w-0">
        <p class="text-sm font-semibold text-gray-900 truncate">{@title}</p>
        <p :if={@subtitle} class="text-xs text-gray-500 truncate mt-0.5">{@subtitle}</p>
      </div>
      {render_slot(@action)}
    </div>
    """
  end
end
