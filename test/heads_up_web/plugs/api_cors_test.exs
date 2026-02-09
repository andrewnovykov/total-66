defmodule HeadsUpWeb.Plugs.ApiCorsTest do
  use HeadsUpWeb.ConnCase, async: true

  describe "API CORS handling" do
    test "adds CORS headers for allowed local Flutter web origin", %{conn: conn} do
      conn =
        conn
        |> put_req_header("origin", "http://localhost:51734")
        |> get("/api/categories")

      assert get_resp_header(conn, "access-control-allow-origin") == ["http://localhost:51734"]
      assert get_resp_header(conn, "access-control-allow-credentials") == ["true"]
    end

    test "responds to API preflight requests", %{conn: conn} do
      conn =
        conn
        |> put_req_header("origin", "http://localhost:51734")
        |> put_req_header("access-control-request-method", "GET")
        |> options("/api/goals")

      assert conn.status == 204
      assert get_resp_header(conn, "access-control-allow-origin") == ["http://localhost:51734"]
      assert get_resp_header(conn, "access-control-allow-methods") != []
    end
  end
end
