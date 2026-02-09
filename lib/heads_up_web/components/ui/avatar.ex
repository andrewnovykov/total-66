defmodule HeadsUpWeb.Components.UI.Avatar do
  use Phoenix.Component

  attr :src, :string, default: nil
  attr :name, :string, required: true
  attr :size, :atom, values: [:xs, :sm, :md, :lg, :xl, :xxl], default: :md
  attr :class, :string, default: ""
  attr :online, :boolean, default: false
  attr :rounded, :atom, values: [:full, :xl, :xxl], default: :full

  def avatar(assigns) do
    fallback = fallback_url(assigns.name)
    has_image = is_binary(assigns.src) and assigns.src != ""

    assigns =
      assigns
      |> assign(:fallback_url, fallback)
      |> assign(:has_image, has_image)

    ~H"""
    <div class={["relative inline-flex shrink-0", size_class(@size), @class]}>
      <div
        class={[
          "w-full h-full overflow-hidden bg-center bg-no-repeat bg-cover",
          rounded_class(@rounded)
        ]}
        style={"background-image: url('#{@fallback_url}');"}
      >
        <img
          :if={@has_image}
          src={@src}
          alt=""
          class="w-full h-full object-cover"
          onerror="this.remove()"
        />
      </div>
      <span
        :if={@online}
        class="absolute bottom-0 right-0 w-3 h-3 bg-green-400 border-2 border-white rounded-full"
      />
    </div>
    """
  end

  defp fallback_url(name) when is_binary(name) and name != "" do
    "https://ui-avatars.com/api/?name=#{URI.encode(name)}&background=6366f1&color=ffffff&size=128&bold=true"
  end

  defp fallback_url(_),
    do: "https://ui-avatars.com/api/?name=U&background=6366f1&color=ffffff&size=128&bold=true"

  defp size_class(:xs), do: "w-6 h-6"
  defp size_class(:sm), do: "w-8 h-8"
  defp size_class(:md), do: "w-10 h-10"
  defp size_class(:lg), do: "w-14 h-14"
  defp size_class(:xl), do: "w-20 h-20"
  defp size_class(:xxl), do: "w-28 h-28 sm:w-32 sm:h-32"

  defp rounded_class(:full), do: "rounded-full"
  defp rounded_class(:xl), do: "rounded-2xl"
  defp rounded_class(:xxl), do: "rounded-[28px]"
end
