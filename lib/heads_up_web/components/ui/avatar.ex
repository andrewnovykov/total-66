defmodule HeadsUpWeb.Components.UI.Avatar do
  use Phoenix.Component

  attr :name, :string, required: true
  attr :src, :string, default: nil
  attr :size, :atom, values: [:xs, :sm, :md, :lg, :xl, :xxl], default: :md
  attr :class, :string, default: ""
  attr :online, :boolean, default: false
  attr :rounded, :atom, values: [:full, :xl, :xxl], default: :full

  def avatar(assigns) do
    initials = get_initials(assigns.name)
    assigns = assign(assigns, :initials, initials)

    ~H"""
    <div class={["relative inline-flex shrink-0", size_class(@size), @class]}>
      <div
        class={[
          "w-full h-full flex items-center justify-center bg-[rgba(255,255,255,0.03)] border border-t66",
          rounded_class(@rounded),
          font_class(@size)
        ]}
      >
        <span class="font-display tracking-[2px] text-t66-text-muted">{@initials}</span>
      </div>
      <span
        :if={@online}
        class="absolute bottom-0 right-0 w-3 h-3 bg-green-400 border-2 border-t66-card rounded-full"
      />
    </div>
    """
  end

  defp get_initials(name) when is_binary(name) and name != "" do
    name
    |> String.split(" ", trim: true)
    |> Enum.take(2)
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
  end

  defp get_initials(_), do: "U"

  defp size_class(:xs), do: "w-6 h-6"
  defp size_class(:sm), do: "w-8 h-8"
  defp size_class(:md), do: "w-10 h-10"
  defp size_class(:lg), do: "w-14 h-14"
  defp size_class(:xl), do: "w-20 h-20"
  defp size_class(:xxl), do: "w-28 h-28 sm:w-32 sm:h-32"

  defp font_class(:xs), do: "text-[0.5rem]"
  defp font_class(:sm), do: "text-[0.6rem]"
  defp font_class(:md), do: "text-[0.85rem]"
  defp font_class(:lg), do: "text-[1rem]"
  defp font_class(:xl), do: "text-[1.6rem]"
  defp font_class(:xxl), do: "text-[2.5rem]"

  defp rounded_class(:full), do: "rounded-full"
  defp rounded_class(:xl), do: "rounded-2xl"
  defp rounded_class(:xxl), do: "rounded-[28px]"
end
