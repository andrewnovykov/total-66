defmodule HeadsUpWeb.Components.UI.SectionHeader do
  use Phoenix.Component

  attr :title, :string, required: true
  attr :link_text, :string, default: nil
  attr :link_to, :string, default: nil
  attr :class, :string, default: ""

  def section_header(assigns) do
    ~H"""
    <div class={["flex items-center justify-between mb-6", @class]}>
      <h2 class="text-2xl font-extrabold text-slate-900">{@title}</h2>
      <.link
        :if={@link_text}
        navigate={@link_to}
        class="text-sm font-bold text-blue-600 hover:text-blue-700 transition-colors"
      >
        {@link_text}
      </.link>
    </div>
    """
  end
end
