defmodule HeadsUpWeb.Components.UI.CategoryCard do
  use Phoenix.Component

  attr :name, :string, required: true
  attr :image, :string, default: nil
  attr :count, :integer, default: 0
  attr :navigate, :string, default: nil

  def category_card(assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      class="flex items-center gap-3 p-3 rounded-2xl hover:bg-white hover:shadow-[0_4px_20px_rgba(0,0,0,0.05)] transition-all"
    >
      <img :if={@image} src={@image} alt={@name} class="w-12 h-12 rounded-xl object-cover" />
      <div
        :if={!@image}
        class="w-12 h-12 rounded-xl bg-gradient-to-br from-pink-200 to-indigo-200 flex items-center justify-center"
      >
        <span class="text-sm font-bold text-indigo-600">
          {String.first(@name)}
        </span>
      </div>
      <div>
        <p class="font-semibold text-sm text-gray-900">{@name}</p>
        <p class="text-xs text-gray-500">{@count} goals</p>
      </div>
    </.link>
    """
  end
end
