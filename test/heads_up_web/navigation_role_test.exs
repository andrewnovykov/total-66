defmodule HeadsUpWeb.NavigationRoleTest do
  use HeadsUpWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HeadsUp.AuthFixtures

  describe "navigation links based on role" do
    test "guest user does not see Coach Center or Admin links", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/all-goals")

      refute html =~ "Coach Center"
      refute html =~ ~r/href="\/admin\/categories"/
      refute html =~ ~r/href="\/admin\/challenge-categories"/
    end

    test "regular user does not see Coach Center or Admin links", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/all-goals")

      refute html =~ "Coach Center"
      refute html =~ ~r/href="\/admin\/categories"/
      refute html =~ ~r/href="\/admin\/challenge-categories"/
    end

    # Coach Center menu is hidden for now
    test "coach user does not see Coach Center link (hidden for now)", %{conn: conn} do
      coach = coach_fixture()
      conn = log_in_user(conn, coach)

      {:ok, _lv, html} = live(conn, ~p"/all-goals")

      refute html =~ "Coach Center"
      refute html =~ ~r/href="\/admin\/categories"/
      refute html =~ ~r/href="\/admin\/challenge-categories"/
    end

    test "admin user sees Admin links but not Coach Center (hidden for now)", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/all-goals")

      refute html =~ "Coach Center"
      # Admin has two links: Goal Categories and Challenge Categories
      assert html =~ "Goal Categories"
      assert html =~ ~r/href="\/admin\/categories"/
      assert html =~ "Challenge Categories"
      assert html =~ ~r/href="\/admin\/challenge-categories"/
    end
  end

  describe "authenticated user navigation" do
    test "shows user name in navigation when logged in", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/all-goals")

      assert html =~ user.name
    end

    test "shows login/register links when not logged in", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/all-goals")

      assert html =~ "Log in"
      assert html =~ "Register"
    end
  end
end
