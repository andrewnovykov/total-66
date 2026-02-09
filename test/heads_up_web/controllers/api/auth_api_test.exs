defmodule HeadsUpWeb.Api.AuthAPITest do
  use HeadsUpWeb.ConnCase

  import HeadsUp.AuthFixtures, only: [valid_user_password: 0]

  setup %{conn: conn} do
    %{conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "POST /api/auth/login" do
    test "logs in with valid credentials", %{conn: conn} do
      user = HeadsUp.AuthFixtures.user_fixture()

      conn =
        post(conn, "/api/auth/login", %{
          "email" => user.email,
          "password" => valid_user_password()
        })

      response = json_response(conn, 200)
      assert response["success"] == true
      assert response["message"] == "Logged in successfully"
      assert response["data"]["id"] == user.id
      assert response["data"]["email"] == user.email
    end

    test "supports nested user payload", %{conn: conn} do
      user = HeadsUp.AuthFixtures.user_fixture()

      conn =
        post(conn, "/api/auth/login", %{
          "user" => %{
            "email" => user.email,
            "password" => valid_user_password()
          }
        })

      response = json_response(conn, 200)
      assert response["success"] == true
      assert response["data"]["id"] == user.id
    end

    test "returns 401 for invalid credentials", %{conn: conn} do
      user = HeadsUp.AuthFixtures.user_fixture()

      conn =
        post(conn, "/api/auth/login", %{
          "email" => user.email,
          "password" => "wrong-password"
        })

      response = json_response(conn, 401)
      assert response["success"] == false
      assert response["error"]["message"] == "Invalid email or password"
    end

    test "returns 400 when params are missing", %{conn: conn} do
      conn = post(conn, "/api/auth/login", %{})
      response = json_response(conn, 400)

      assert response["success"] == false
      assert response["error"]["message"] == "Email and password are required"
    end
  end

  describe "GET /api/auth/me" do
    test "returns 401 when unauthenticated", %{conn: conn} do
      conn = get(conn, "/api/auth/me")
      response = json_response(conn, 401)

      assert response["success"] == false
      assert response["error"]["message"] == "Authentication required"
    end

    test "returns current user when authenticated", %{conn: conn} do
      user = HeadsUp.AuthFixtures.user_fixture()

      conn =
        post(conn, "/api/auth/login", %{
          "email" => user.email,
          "password" => valid_user_password()
        })

      conn =
        conn
        |> recycle()
        |> get("/api/auth/me")

      response = json_response(conn, 200)
      assert response["success"] == true
      assert response["data"]["id"] == user.id
      assert response["data"]["email"] == user.email
    end
  end

  describe "DELETE /api/auth/logout" do
    test "logs out and invalidates session", %{conn: conn} do
      user = HeadsUp.AuthFixtures.user_fixture()

      conn =
        post(conn, "/api/auth/login", %{
          "email" => user.email,
          "password" => valid_user_password()
        })

      conn =
        conn
        |> recycle()
        |> delete("/api/auth/logout")

      response = json_response(conn, 200)
      assert response["success"] == true
      assert response["message"] == "Logged out successfully"

      conn =
        conn
        |> recycle()
        |> get("/api/auth/me")

      response = json_response(conn, 401)
      assert response["success"] == false
      assert response["error"]["message"] == "Authentication required"
    end
  end
end
