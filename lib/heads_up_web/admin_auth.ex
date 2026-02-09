defmodule HeadsUpWeb.AdminAuth do
  @moduledoc """
  Plug and LiveView on_mount callback for requiring admin role access.
  """
  import Plug.Conn
  import Phoenix.Controller
  import HeadsUpWeb.Helpers.RoleHelper

  def require_admin_user(conn, _opts) do
    if is_admin?(conn.assigns[:current_user]) do
      conn
    else
      conn
      |> put_flash(:error, "Access denied. Admin privileges required.")
      |> redirect(to: "/")
      |> halt()
    end
  end

  def on_mount(:ensure_admin, _params, _session, socket) do
    if is_admin?(socket.assigns.current_user) do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "Access denied. Admin privileges required.")
        |> Phoenix.LiveView.redirect(to: "/")

      {:halt, socket}
    end
  end
end
