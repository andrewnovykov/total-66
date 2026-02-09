defmodule HeadsUpWeb.CoachAuth do
  @moduledoc """
  Plug and LiveView on_mount callback for requiring coach role access.

  Coaches and admins can access coach-only routes.
  """
  import Plug.Conn
  import Phoenix.Controller
  import HeadsUpWeb.Helpers.RoleHelper

  def require_coach_user(conn, _opts) do
    if is_coach_or_admin?(conn.assigns[:current_user]) do
      conn
    else
      conn
      |> put_flash(:error, "Access denied. Coach privileges required.")
      |> redirect(to: "/")
      |> halt()
    end
  end

  def on_mount(:ensure_coach, _params, _session, socket) do
    if is_coach_or_admin?(socket.assigns.current_user) do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "Access denied. Coach privileges required.")
        |> Phoenix.LiveView.redirect(to: "/")

      {:halt, socket}
    end
  end
end
