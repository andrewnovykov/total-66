defmodule HeadsUpWeb.UserRegistrationLiveTest do
  use HeadsUpWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HeadsUp.AuthFixtures

  describe "Registration page" do
    test "renders registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register")

      assert html =~ "Register"
      assert html =~ "Log in"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/register")
        |> follow_redirect(conn, "/")

      assert {:ok, _conn} = result
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"email" => "with spaces", "password" => "too short"})

      assert result =~ "Register"
      assert result =~ "must have the @ sign and no spaces"
      assert result =~ "should be at least 12 character"
    end
  end

  describe "register user" do
    test "creates account and logs the user in", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      email = unique_user_email()
      form = form(lv, "#registration_form", user: valid_user_attributes(email: email))
      render_submit(form)
      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      user = HeadsUp.Auth.get_user_by_email(email)
      assert response =~ user.name
      assert response =~ "Settings"
      assert response =~ "Log out"
    end

    test "renders errors for duplicated email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      user = user_fixture(%{email: "test@email.com"})

      result =
        lv
        |> form("#registration_form",
          user: %{"email" => user.email, "password" => "valid_password"}
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end
  end

  describe "registration navigation" do
    test "redirects to login page when the Log in button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      {:ok, _login_live, login_html} =
        lv
        |> element(~s|a.font-bold.text-blue-600:fl-contains("Log in")|)
        |> render_click()
        |> follow_redirect(conn, ~p"/users/log_in")

      assert login_html =~ "Log in"
    end
  end

  describe "role selection" do
    test "registration form shows role selector", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register")

      assert html =~ "I am registering as"
      assert html =~ "Regular User"
      # Coach option is hidden for now
      refute html =~ ~r/<option[^>]*value="coach"[^>]*>Coach</
    end

    test "can register as regular user (default)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      email = unique_user_email()
      attrs = valid_user_attributes(email: email, role: "user")
      form = form(lv, "#registration_form", user: attrs)
      render_submit(form)
      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/"

      # Verify user was created with user role
      user = HeadsUp.Auth.get_user_by_email(email)
      assert user.role == "user"
    end

    # Coach registration hidden for now
    # test "can register as coach" — coach option removed from selector

    test "role selector does not include admin option", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register")

      # Admin should not be a selectable option (admins are created via console/database)
      refute html =~ ~r/<option[^>]*value="admin"[^>]*>Admin</
    end
  end
end
