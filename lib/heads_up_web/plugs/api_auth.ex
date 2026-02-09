defmodule HeadsUpWeb.Plugs.ApiAuth do
  @moduledoc """
  Plug that authenticates API requests via Bearer token.
  Falls through silently if no token is present (allows session auth to work).
  Only sets current_user if not already set by session auth.
  """

  import Plug.Conn
  alias HeadsUp.Auth

  def init(opts), do: opts

  def call(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
           %{} = user <- Auth.get_user_by_api_token(token) do
        assign(conn, :current_user, user)
      else
        _ -> conn
      end
    end
  end
end
