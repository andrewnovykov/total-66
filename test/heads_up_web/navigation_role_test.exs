defmodule HeadsUpWeb.NavigationRoleTest do
  use HeadsUpWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HeadsUp.AuthFixtures

  describe "topnav navigation links" do
    test "guest user sees Login link in topnav", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/people")

      assert html =~ "Login"
    end

    test "logged-in user sees avatar link in topnav", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/people")

      # Avatar circle links to My Hub
      assert html =~ ~r/href="\/my-challenges"/
    end
  end

  describe "sidebar navigation links based on role" do
    test "regular user does not see Admin links in sidebar", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/my-challenges")

      refute html =~ "Coach Center"
      refute html =~ ~r/href="\/admin\/challenge-categories"/
    end

    # Coach Center menu is hidden for now
    test "coach user does not see Coach Center link (hidden for now)", %{conn: conn} do
      coach = coach_fixture()
      conn = log_in_user(conn, coach)

      {:ok, _lv, html} = live(conn, ~p"/my-challenges")

      refute html =~ "Coach Center"
      refute html =~ ~r/href="\/admin\/challenge-categories"/
    end

    test "admin user sees Admin links in sidebar", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/my-challenges")

      refute html =~ "Coach Center"
      assert html =~ "Challenge Categories"
      assert html =~ ~r/href="\/admin\/challenge-categories"/
    end

    test "sidebar shows user name when logged in", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/my-challenges")

      assert html =~ user.name
    end
  end
end
