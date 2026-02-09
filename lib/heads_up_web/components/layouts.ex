defmodule HeadsUpWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use HeadsUpWeb, :controller` and
  `use HeadsUpWeb, :live_view`.
  """
  use HeadsUpWeb, :html

  embed_templates "layouts/*"

  attr :href, :string, required: true
  attr :label, :string, required: true
  attr :icon, :string, required: true

  defp sidebar_link(assigns) do
    ~H"""
    <a
      href={@href}
      class="flex items-center gap-4 px-6 py-4 rounded-2xl text-slate-500 hover:bg-slate-50 transition-all font-bold text-sm"
    >
      <.icon name={@icon} class="w-5 h-5" />
      <span>{@label}</span>
    </a>
    """
  end

  attr :href, :string, required: true
  attr :label, :string, required: true
  attr :icon, :string, required: true
  attr :x_click, :string, default: nil

  defp drawer_link(assigns) do
    ~H"""
    <a
      href={@href}
      x-on:click={@x_click}
      class="flex items-center gap-3 rounded-2xl px-6 py-3 text-sm font-bold text-slate-500 transition hover:bg-slate-50"
    >
      <.icon name={@icon} class="w-5 h-5" />
      <span>{@label}</span>
    </a>
    """
  end
end
