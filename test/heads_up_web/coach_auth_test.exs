defmodule HeadsUpWeb.CoachAuthTest do
  use HeadsUpWeb.ConnCase, async: true

  alias Phoenix.LiveView
  alias HeadsUp.Auth
  alias HeadsUpWeb.CoachAuth
  import HeadsUp.AuthFixtures

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, HeadsUpWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{conn: conn}
  end

  describe "require_coach_user/2 plug" do
    test "allows coach user to proceed", %{conn: conn} do
      coach = coach_fixture()
      conn = conn |> assign(:current_user, coach) |> CoachAuth.require_coach_user([])

      refute conn.halted
      refute conn.status
    end

    test "allows admin user to proceed (admin has coach privileges)", %{conn: conn} do
      admin = admin_fixture()
      conn = conn |> assign(:current_user, admin) |> CoachAuth.require_coach_user([])

      refute conn.halted
      refute conn.status
    end

    test "redirects regular user", %{conn: conn} do
      user = user_fixture()

      conn =
        conn |> assign(:current_user, user) |> fetch_flash() |> CoachAuth.require_coach_user([])

      assert conn.halted
      assert redirected_to(conn) == "/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "Access denied. Coach privileges required."
    end

    test "redirects when no user is logged in", %{conn: conn} do
      conn =
        conn |> assign(:current_user, nil) |> fetch_flash() |> CoachAuth.require_coach_user([])

      assert conn.halted
      assert redirected_to(conn) == "/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "Access denied. Coach privileges required."
    end

    test "redirects when current_user is not set", %{conn: conn} do
      conn = conn |> fetch_flash() |> CoachAuth.require_coach_user([])

      assert conn.halted
      assert redirected_to(conn) == "/"
    end
  end

  describe "on_mount :ensure_coach for LiveView" do
    test "allows coach user to continue", %{conn: conn} do
      coach = coach_fixture()
      user_token = Auth.generate_user_session_token(coach)
      session = conn |> put_session(:user_token, user_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: HeadsUpWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}, current_user: coach}
      }

      {:cont, updated_socket} = CoachAuth.on_mount(:ensure_coach, %{}, session, socket)
      assert updated_socket.assigns.current_user.id == coach.id
    end

    test "allows admin user to continue (admin has coach privileges)", %{conn: conn} do
      admin = admin_fixture()
      user_token = Auth.generate_user_session_token(admin)
      session = conn |> put_session(:user_token, user_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: HeadsUpWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}, current_user: admin}
      }

      {:cont, updated_socket} = CoachAuth.on_mount(:ensure_coach, %{}, session, socket)
      assert updated_socket.assigns.current_user.id == admin.id
    end

    test "halts regular user with redirect", %{conn: conn} do
      user = user_fixture()
      user_token = Auth.generate_user_session_token(user)
      session = conn |> put_session(:user_token, user_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: HeadsUpWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}, current_user: user}
      }

      {:halt, updated_socket} = CoachAuth.on_mount(:ensure_coach, %{}, session, socket)
      assert updated_socket.assigns.current_user.id == user.id
    end

    test "halts when no user is logged in", %{conn: conn} do
      session = conn |> get_session()

      socket = %LiveView.Socket{
        endpoint: HeadsUpWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}, current_user: nil}
      }

      {:halt, _updated_socket} = CoachAuth.on_mount(:ensure_coach, %{}, session, socket)
    end
  end

  describe "role hierarchy" do
    test "coach role is below admin in hierarchy" do
      admin = admin_fixture()
      coach = coach_fixture()
      user = user_fixture()

      # Admin can access coach features
      assert admin.role in ["coach", "admin"]
      # Coach can access coach features
      assert coach.role in ["coach", "admin"]
      # Regular user cannot
      refute user.role in ["coach", "admin"]
    end
  end
end
