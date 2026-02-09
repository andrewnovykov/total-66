defmodule HeadsUpWeb.Components.UI.StatusBadge do
  use Phoenix.Component

  attr :status, :atom, required: true
  attr :size, :atom, values: [:sm, :md], default: :sm

  def status_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center gap-1.5 font-bold rounded-full",
      status_style(@status),
      badge_size(@size)
    ]}>
      <span class={["rounded-full", dot_size(@size), dot_color(@status)]} />
      {status_label(@status)}
    </span>
    """
  end

  defp status_style(:active), do: "bg-green-50 text-green-600"
  defp status_style(:completed), do: "bg-blue-50 text-blue-600"
  defp status_style(:paused), do: "bg-amber-50 text-amber-600"
  defp status_style(:cancelled), do: "bg-slate-100 text-slate-500"
  defp status_style(:failed), do: "bg-red-50 text-red-600"
  defp status_style(_), do: "bg-slate-100 text-slate-500"

  defp dot_color(:active), do: "bg-green-500"
  defp dot_color(:completed), do: "bg-blue-500"
  defp dot_color(:paused), do: "bg-amber-500"
  defp dot_color(:cancelled), do: "bg-slate-400"
  defp dot_color(:failed), do: "bg-red-500"
  defp dot_color(_), do: "bg-slate-400"

  defp badge_size(:sm), do: "px-3 py-1.5 text-xs"
  defp badge_size(:md), do: "px-4 py-2 text-sm"

  defp dot_size(:sm), do: "w-2 h-2"
  defp dot_size(:md), do: "w-2.5 h-2.5"

  defp status_label(:active), do: "Active"
  defp status_label(:completed), do: "Completed"
  defp status_label(:paused), do: "Paused"
  defp status_label(:cancelled), do: "Cancelled"
  defp status_label(:failed), do: "Failed"
  defp status_label(status), do: status |> to_string() |> String.capitalize()
end
