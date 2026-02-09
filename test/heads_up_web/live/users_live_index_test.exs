defmodule HeadsUpWeb.UsersLiveIndexTest do
  use HeadsUpWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HeadsUp.AuthFixtures

  describe "people directory page" do
    test "renders for guest users", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/people")

      assert html =~ "Members"
      assert html =~ "Community"
    end

    test "renders for authenticated users", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, _lv, html} = live(conn, ~p"/people")

      assert html =~ "Members"
    end

    test "displays users in the directory", %{conn: conn} do
      _user1 = user_fixture(%{name: "Alice Johnson", user_name: "alice_test"})
      _user2 = user_fixture(%{name: "Bob Smith", user_name: "bob_test"})

      {:ok, _lv, html} = live(conn, ~p"/people")

      assert html =~ "Alice Johnson"
      assert html =~ "Bob Smith"
    end

    test "search filters users by name", %{conn: conn} do
      _user1 = user_fixture(%{name: "Alice Johnson", user_name: "alice_search"})
      _user2 = user_fixture(%{name: "Bob Smith", user_name: "bob_search"})

      {:ok, lv, _html} = live(conn, ~p"/people")

      html = lv |> element("form") |> render_change(%{"search" => %{"query" => "Alice"}})

      assert html =~ "Alice Johnson"
      refute html =~ "Bob Smith"
    end

    test "search filters users by username", %{conn: conn} do
      _user1 = user_fixture(%{name: "Alice Johnson", user_name: "alice_uname"})
      _user2 = user_fixture(%{name: "Bob Smith", user_name: "bob_uname"})

      {:ok, lv, _html} = live(conn, ~p"/people")

      html = lv |> element("form") |> render_change(%{"search" => %{"query" => "bob_uname"}})

      refute html =~ "Alice Johnson"
      assert html =~ "Bob Smith"
    end

    test "empty search shows all users", %{conn: conn} do
      _user1 = user_fixture(%{name: "Alice Empty", user_name: "alice_empty"})
      _user2 = user_fixture(%{name: "Bob Empty", user_name: "bob_empty"})

      {:ok, lv, _html} = live(conn, ~p"/people")

      # Search then clear
      lv |> element("form") |> render_change(%{"search" => %{"query" => "Alice"}})
      html = lv |> element("form") |> render_change(%{"search" => %{"query" => ""}})

      assert html =~ "Alice Empty"
      assert html =~ "Bob Empty"
    end

    test "user cards link to profiles", %{conn: conn} do
      user = user_fixture(%{name: "Profile Link User", user_name: "profilelink"})

      {:ok, _lv, html} = live(conn, ~p"/people")

      assert html =~ ~p"/people/#{user.user_name}"
    end
  end
end
