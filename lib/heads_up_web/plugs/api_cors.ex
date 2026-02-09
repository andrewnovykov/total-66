defmodule HeadsUpWeb.Plugs.ApiCors do
  @moduledoc """
  Minimal CORS handling for API routes so Flutter web (localhost random port)
  can call the Phoenix JSON API during local development.
  """
  import Plug.Conn

  @allowed_origins [
    ~r/^http:\/\/localhost:\d+$/,
    ~r/^http:\/\/127\.0\.0\.1:\d+$/,
    ~r/^https:\/\/localhost:\d+$/,
    ~r/^https:\/\/127\.0\.0\.1:\d+$/
  ]

  @allowed_headers "content-type,authorization,x-requested-with"
  @allowed_methods "GET,POST,PUT,PATCH,DELETE,OPTIONS"

  def init(opts), do: opts

  def call(conn, _opts) do
    if api_request?(conn) do
      origin = conn |> get_req_header("origin") |> List.first()

      cond do
        is_nil(origin) ->
          conn

        allowed_origin?(origin) ->
          conn
          |> put_resp_header("vary", "origin")
          |> put_resp_header("access-control-allow-origin", origin)
          |> put_resp_header("access-control-allow-credentials", "true")
          |> put_resp_header("access-control-allow-headers", @allowed_headers)
          |> put_resp_header("access-control-allow-methods", @allowed_methods)
          |> maybe_reply_options()

        conn.method == "OPTIONS" ->
          conn
          |> send_resp(:forbidden, "")
          |> halt()

        true ->
          conn
      end
    else
      conn
    end
  end

  defp api_request?(%Plug.Conn{path_info: ["api" | _]}), do: true
  defp api_request?(_), do: false

  defp allowed_origin?(origin) do
    Enum.any?(@allowed_origins, fn pattern -> Regex.match?(pattern, origin) end)
  end

  defp maybe_reply_options(%Plug.Conn{method: "OPTIONS"} = conn) do
    conn
    |> send_resp(:no_content, "")
    |> halt()
  end

  defp maybe_reply_options(conn), do: conn
end
