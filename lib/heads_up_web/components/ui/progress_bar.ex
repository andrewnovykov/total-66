defmodule HeadsUpWeb.Components.UI.ProgressBar do
  use Phoenix.Component

  attr :value, :integer, default: 0
  attr :max, :integer, default: 100
  attr :size, :atom, values: [:sm, :md, :lg], default: :md

  attr :color, :atom,
    values: [:blue, :green, :red, :purple, :coral, :indigo, :yellow],
    default: :blue

  attr :show_label, :boolean, default: true

  def progress_bar(assigns) do
    percentage = min(round(assigns.value / max(assigns.max, 1) * 100), 100)
    assigns = assign(assigns, :percentage, percentage)

    ~H"""
    <div class="w-full">
      <div :if={@show_label} class="flex justify-between items-center mb-2">
        <span class="text-sm font-bold text-slate-500">Goal Progress</span>
        <span class={["text-sm font-extrabold", label_color(@color)]}>{@percentage}%</span>
      </div>
      <div class={["w-full bg-slate-100 rounded-full overflow-hidden", bar_height(@size)]}>
        <div
          class={["rounded-full transition-all duration-500", bar_color(@color), bar_height(@size)]}
          style={"width: #{@percentage}%"}
        />
      </div>
    </div>
    """
  end

  defp bar_height(:sm), do: "h-2"
  defp bar_height(:md), do: "h-3"
  defp bar_height(:lg), do: "h-4"

  defp bar_color(:blue), do: "bg-blue-500"
  defp bar_color(:green), do: "bg-green-500"
  defp bar_color(:red), do: "bg-red-500"
  defp bar_color(:purple), do: "bg-purple-500"
  defp bar_color(:coral), do: "bg-[#FF6B6B]"
  defp bar_color(:indigo), do: "bg-indigo-500"
  defp bar_color(:yellow), do: "bg-yellow-400"

  defp label_color(:blue), do: "text-blue-600"
  defp label_color(:green), do: "text-green-600"
  defp label_color(:red), do: "text-red-600"
  defp label_color(:purple), do: "text-purple-600"
  defp label_color(:coral), do: "text-[#FF6B6B]"
  defp label_color(:indigo), do: "text-indigo-600"
  defp label_color(:yellow), do: "text-yellow-600"
end
