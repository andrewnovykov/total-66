defmodule HeadsUpWeb.Api.AuthController do
  use HeadsUpWeb, :controller

  alias HeadsUp.Auth

  action_fallback HeadsUpWeb.FallbackController

  # POST /api/auth/register
  def register(
        conn,
        %{"email" => email, "password" => password, "name" => name, "user_name" => user_name} =
          params
      ) do
    attrs = %{
      email: email,
      password: password,
      name: name,
      user_name: user_name,
      bio: params["bio"] || ""
    }

    case Auth.register_user(attrs) do
      {:ok, user} ->
        api_token = Auth.generate_user_api_token(user)

        conn
        |> put_status(:created)
        |> render(:registration, user: user, token: api_token)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:changeset_error, changeset: changeset)
    end
  end

  def register(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> render(:error, message: "email, password, name, and user_name are required")
  end

  # POST /api/auth/login
  def login(conn, %{"email" => email, "password" => password}) do
    do_login(conn, email, password)
  end

  def login(conn, %{"user" => %{"email" => email, "password" => password}}) do
    do_login(conn, email, password)
  end

  def login(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> render(:error, message: "Email and password are required")
  end

  # GET /api/auth/me
  def me(conn, _params) do
    conn
    |> put_status(:ok)
    |> render(:user, user: conn.assigns.current_user)
  end

  # DELETE /api/auth/logout
  def logout(conn, _params) do
    if user_token = get_session(conn, :user_token) do
      Auth.delete_user_session_token(user_token)
    end

    conn
    |> renew_session()
    |> put_status(:ok)
    |> render(:action_success, message: "Logged out successfully")
  end

  defp do_login(conn, email, password) when is_binary(email) and is_binary(password) do
    case Auth.get_user_by_email_and_password(email, password) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> render(:error, message: "Invalid email or password")

      user ->
        session_token = Auth.generate_user_session_token(user)
        api_token = Auth.generate_user_api_token(user)

        conn
        |> renew_session()
        |> put_session(:user_token, session_token)
        |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(session_token)}")
        |> put_status(:ok)
        |> render(:session, user: user, token: api_token, message: "Logged in successfully")
    end
  end

  defp do_login(conn, _email, _password) do
    conn
    |> put_status(:bad_request)
    |> render(:error, message: "Email and password must be strings")
  end

  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end
end
