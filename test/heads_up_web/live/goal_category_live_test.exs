defmodule HeadsUpWeb.GoalCategoryLiveTest do
  use HeadsUpWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HeadsUp.AuthFixtures

  alias HeadsUp.Groups

  setup do
    # Create test categories
    {:ok, category1} =
      Groups.create_group(%{
        name: "Fitness",
        description: "Health and fitness goals",
        image_path: "/images/fitness.jpg",
        status: :published
      })

    {:ok, category2} =
      Groups.create_group(%{
        name: "Career",
        description: "Professional development goals",
        image_path: "/images/career.jpg",
        status: :published
      })

    {:ok, unpublished} =
      Groups.create_group(%{
        name: "Draft Category",
        description: "Not yet published",
        image_path: "/images/draft.jpg",
        status: :unpublished
      })

    %{
      category1: category1,
      category2: category2,
      unpublished: unpublished
    }
  end

  describe "Goal Category Index page" do
    test "renders goal categories page with categories", %{
      conn: conn,
      category1: cat1,
      category2: cat2
    } do
      {:ok, _view, html} = live(conn, ~p"/goals-category")

      assert html =~ "Goal Categories"
      assert html =~ cat1.name
      assert html =~ cat2.name
    end

    test "shows only published categories", %{conn: conn, category1: cat1, unpublished: unpub} do
      {:ok, _view, html} = live(conn, ~p"/goals-category")

      assert html =~ cat1.name
      refute html =~ unpub.name
    end

    test "search filters categories", %{conn: conn, category1: cat1, category2: cat2} do
      {:ok, view, _html} = live(conn, ~p"/goals-category")

      # Search for "Fitness" - center grid should only show matching categories
      view |> element("form") |> render_change(%{"query" => "Fitness"})

      # The matching category card should be in the grid
      assert has_element?(view, ".grid h3", cat1.name)
      # The non-matching category should NOT be in the grid
      refute has_element?(view, ".grid h3", cat2.name)
    end

    test "clicking category navigates to category page", %{conn: conn, category1: cat1} do
      {:ok, view, _html} = live(conn, ~p"/goals-category")

      # Click the category card in the grid (not the sidebar row)
      view |> element(".grid div[phx-value-group-id='#{cat1.id}']") |> render_click()

      assert_redirect(view, ~p"/goals-category/#{cat1.id}")
    end

    test "shows empty state when no categories match search", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/goals-category")

      html = view |> element("form") |> render_change(%{"query" => "nonexistent123"})

      assert html =~ "No categories match your search"
    end
  end

  describe "Admin Manage Categories button" do
    test "guest user does not see Manage Categories button", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/goals-category")

      refute html =~ "Manage Categories"
    end

    test "regular user does not see Manage Categories button", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _view, html} = live(conn, ~p"/goals-category")

      refute html =~ "Manage Categories"
    end

    test "coach user does not see Manage Categories button", %{conn: conn} do
      coach = coach_fixture()
      conn = log_in_user(conn, coach)

      {:ok, _view, html} = live(conn, ~p"/goals-category")

      refute html =~ "Manage Categories"
    end

    test "admin user sees Manage Categories button", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)

      {:ok, _view, html} = live(conn, ~p"/goals-category")

      assert html =~ "Manage Categories"
      assert html =~ ~r/href="\/admin\/categories"/
    end

    test "Manage Categories button links to admin categories page", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)

      {:ok, view, _html} = live(conn, ~p"/goals-category")

      # Click the Manage Categories link - should redirect to admin categories
      view |> element("a", "Manage Categories") |> render_click()
      assert_redirect(view, ~p"/admin/categories")
    end
  end

  describe "Category display" do
    test "shows category image when available", %{conn: conn, category1: cat1} do
      {:ok, _view, html} = live(conn, ~p"/goals-category")

      assert html =~ cat1.image_path
    end

    test "shows category description", %{conn: conn, category1: cat1} do
      {:ok, _view, html} = live(conn, ~p"/goals-category")

      assert html =~ cat1.description
    end

    test "shows goal counts", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/goals-category")

      assert html =~ "goals"
      assert html =~ "active"
    end
  end
end
