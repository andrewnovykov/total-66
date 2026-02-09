defmodule HeadsUpWeb.Components.UI.BottomNav do
  use Phoenix.Component
  import HeadsUpWeb.CoreComponents, only: [icon: 1]

  attr :current_path, :string, required: true
  attr :current_user, :map, default: nil

  def bottom_nav(assigns) do
    ~H"""
    <nav class="fixed bottom-0 left-0 right-0 backdrop-blur-[20px] bg-[rgba(10,10,10,0.85)] border-t border-t66 lg:hidden z-50">
      <div class="flex items-center justify-around h-16 max-w-lg mx-auto px-2">
        <.nav_item icon="hero-home" label="Home" to="/" active={@current_path == "/"} />
        <.nav_item
          icon="hero-magnifying-glass"
          label="Explore"
          to="/challenges"
          active={@current_path == "/challenges"}
        />
        <.nav_item
          icon="hero-plus-circle-solid"
          label="Create"
          to="/challenges/new"
          active={@current_path == "/challenges/new"}
          primary={true}
        />
        <.nav_item
          icon="hero-users"
          label="Members"
          to="/people"
          active={String.starts_with?(@current_path, "/people")}
        />
        <.nav_item
          icon="hero-user"
          label={if @current_user, do: "Profile", else: "Login"}
          to={if @current_user, do: "/people/#{@current_user.user_name}", else: "/users/log_in"}
          active={@current_user && String.starts_with?(@current_path, "/people/#{@current_user && @current_user.user_name}")}
        />
      </div>
    </nav>
    """
  end

  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :to, :string, required: true
  attr :active, :boolean, default: false
  attr :primary, :boolean, default: false

  defp nav_item(assigns) do
    ~H"""
    <.link
      navigate={@to}
      class={[
        "flex flex-col items-center justify-center gap-0.5 min-w-[48px] min-h-[44px] px-2 transition-colors",
        @primary && "text-t66-accent",
        !@primary && @active && "text-t66-accent",
        !@primary && !@active && "text-t66-text-muted"
      ]}
    >
      <.icon name={@icon} class={if @primary, do: "w-7 h-7", else: "w-6 h-6"} />
      <span class="text-[10px] font-medium">{@label}</span>
    </.link>
    """
  end
end
