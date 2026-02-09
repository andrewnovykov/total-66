defmodule HeadsUpWeb.Components.UI.EmptyState do
  use Phoenix.Component
  import HeadsUpWeb.CoreComponents, only: [icon: 1]

  attr :icon, :string, default: "hero-inbox"
  attr :title, :string, required: true
  attr :message, :string, default: nil
  slot :action

  def empty_state(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center py-20 px-8 text-center rounded-[40px] bg-white soft-shadow border border-slate-50">
      <div class="w-20 h-20 rounded-full bg-slate-100 flex items-center justify-center mb-6">
        <.icon name={@icon} class="w-10 h-10 text-slate-400" />
      </div>
      <h3 class="text-xl font-extrabold text-slate-900">{@title}</h3>
      <p :if={@message} class="text-sm text-slate-400 mt-2 max-w-sm">{@message}</p>
      <div :if={@action != []} class="mt-6">
        {render_slot(@action)}
      </div>
    </div>
    """
  end
end
