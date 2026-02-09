defmodule HeadsUpWeb.Components.UI.Tag do
  use Phoenix.Component

  attr :label, :string, required: true

  attr :color, :atom,
    values: [:blue, :green, :red, :yellow, :purple, :pink, :gray, :indigo],
    default: :blue

  attr :size, :atom, values: [:sm, :md], default: :sm

  def tag(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center font-bold rounded-full",
      color_class(@color),
      size_class(@size)
    ]}>
      {@label}
    </span>
    """
  end

  defp color_class(:blue), do: "bg-blue-50 text-blue-600"
  defp color_class(:green), do: "bg-green-50 text-green-600"
  defp color_class(:red), do: "bg-red-50 text-red-600"
  defp color_class(:yellow), do: "bg-yellow-50 text-yellow-600"
  defp color_class(:purple), do: "bg-purple-50 text-purple-600"
  defp color_class(:pink), do: "bg-pink-50 text-pink-600"
  defp color_class(:gray), do: "bg-slate-100 text-slate-600"
  defp color_class(:indigo), do: "bg-indigo-50 text-indigo-600"

  defp size_class(:sm), do: "px-4 py-2 text-sm"
  defp size_class(:md), do: "px-5 py-2.5 text-sm"
end
