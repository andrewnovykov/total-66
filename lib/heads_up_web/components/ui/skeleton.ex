defmodule HeadsUpWeb.Components.UI.Skeleton do
  use Phoenix.Component

  attr :type, :atom, values: [:text, :avatar, :card, :image], default: :text
  attr :class, :string, default: ""

  def skeleton(assigns) do
    ~H"""
    <div class={["animate-pulse", skeleton_class(@type), @class]} />
    """
  end

  def skeleton_card(assigns) do
    ~H"""
    <div class="bg-white rounded-3xl shadow-[0_4px_20px_rgba(0,0,0,0.05)] p-6 animate-pulse">
      <div class="flex items-center gap-3">
        <div class="w-10 h-10 bg-gray-200 rounded-full" />
        <div class="flex-1 space-y-2">
          <div class="h-4 bg-gray-200 rounded w-1/3" />
          <div class="h-3 bg-gray-200 rounded w-1/4" />
        </div>
      </div>
      <div class="mt-4 space-y-2">
        <div class="h-3 bg-gray-200 rounded w-full" />
        <div class="h-3 bg-gray-200 rounded w-4/5" />
      </div>
    </div>
    """
  end

  defp skeleton_class(:text), do: "h-4 bg-gray-200 rounded"
  defp skeleton_class(:avatar), do: "w-10 h-10 bg-gray-200 rounded-full"
  defp skeleton_class(:card), do: "h-40 bg-gray-200 rounded-3xl"
  defp skeleton_class(:image), do: "h-48 bg-gray-200 rounded-2xl"
end
