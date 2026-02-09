defmodule HeadsUpWeb.Components.UI.UserMiniCard do
  use Phoenix.Component
  alias HeadsUpWeb.Components.UI.Avatar

  attr :name, :string, required: true
  attr :username, :string, default: nil
  attr :avatar, :string, default: nil
  attr :level, :integer, default: nil
  attr :navigate, :string, default: nil
  slot :action

  def user_mini_card(assigns) do
    ~H"""
    <div class="flex items-center gap-4 py-3">
      <Avatar.avatar name={@name} src={@avatar} size={:lg} />
      <div class="flex-1 min-w-0">
        <p class="font-bold text-slate-900 text-sm">{@name}</p>
        <p :if={@username} class="text-slate-400 text-xs">@{@username}</p>
      </div>
      {render_slot(@action)}
    </div>
    """
  end
end
