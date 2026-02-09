defmodule HeadsUpWeb.Components.UI.Card do
  use Phoenix.Component

  attr :class, :string, default: ""
  attr :hover, :boolean, default: false
  attr :padding, :atom, values: [:none, :sm, :md, :lg, :xl], default: :md
  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <div class={[
      "bg-white rounded-[40px]",
      "soft-shadow border border-slate-50",
      @hover && "hover:scale-[1.01] hover:shadow-lg transition-all duration-200",
      padding_class(@padding),
      @class
    ]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp padding_class(:none), do: ""
  defp padding_class(:sm), do: "p-4"
  defp padding_class(:md), do: "p-8"
  defp padding_class(:lg), do: "p-10"
  defp padding_class(:xl), do: "p-12"
end
