defmodule HeadsUpWeb.Admin.GroupsLiveTest do
  use HeadsUpWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HeadsUp.AuthFixtures

  alias HeadsUp.Groups

  setup do
    # Create test category
    {:ok, category} =
      Groups.create_group(%{
        name: "Test Category",
        description: "A test category",
        image_path: "/images/test.jpg",
        status: :published
      })

    %{category: category}
  end

  describe "Access control" do
    test "guest user is redirected from admin categories", %{conn: conn} do
      result = live(conn, ~p"/admin/categories")

      # Should be redirected due to require_authenticated_user
      assert {:error,
              {:redirect,
               %{to: "/users/log_in", flash: %{"error" => "You must log in to access this page."}}}} =
               result
    end

    test "regular user is denied access to admin categories", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      result = live(conn, ~p"/admin/categories")

      assert {:error,
              {:redirect,
               %{to: "/", flash: %{"error" => "Access denied. Admin privileges required."}}}} =
               result
    end

    test "coach user is denied access to admin categories", %{conn: conn} do
      coach = coach_fixture()
      conn = log_in_user(conn, coach)

      result = live(conn, ~p"/admin/categories")

      assert {:error,
              {:redirect,
               %{to: "/", flash: %{"error" => "Access denied. Admin privileges required."}}}} =
               result
    end

    test "admin user can access admin categories", %{conn: conn, category: category} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)

      {:ok, _view, html} = live(conn, ~p"/admin/categories")

      assert html =~ "Goal Categories"
      assert html =~ category.name
    end
  end

  describe "Admin CRUD operations" do
    setup %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)
      %{conn: conn, admin: admin}
    end

    test "displays list of categories", %{conn: conn, category: category} do
      {:ok, _view, html} = live(conn, ~p"/admin/categories")

      assert html =~ category.name
      assert html =~ category.description
      assert html =~ "Published"
    end

    test "shows goal count for each category", %{conn: conn, category: category} do
      {:ok, _view, html} = live(conn, ~p"/admin/categories")

      assert html =~ "0 goals"
    end

    test "can open create category modal", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/categories")

      html =
        view |> element("button[phx-click='show_create_modal']", "New Category") |> render_click()

      assert html =~ "Create New Category"
      assert html =~ "Name"
      assert html =~ "Description"
      assert html =~ "Image URL"
      assert html =~ "Status"
    end

    test "can create a new category", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/categories")

      # Open modal
      view |> element("button[phx-click='show_create_modal']", "New Category") |> render_click()

      # Submit form
      html =
        view
        |> form("form[phx-submit='create_group']", %{
          "group" => %{
            "name" => "New Category",
            "description" => "A new test category",
            "image_path" => "/images/new.jpg",
            "status" => "published"
          }
        })
        |> render_submit()

      assert html =~ "Category created successfully!"
      assert html =~ "New Category"
    end

    test "can edit a category", %{conn: conn, category: category} do
      {:ok, view, _html} = live(conn, ~p"/admin/categories")

      # Open edit modal
      html =
        view
        |> element("button[phx-click='edit_group'][phx-value-id='#{category.id}']")
        |> render_click()

      assert html =~ "Edit Category"

      # Submit update
      html =
        view
        |> form("form[phx-submit='update_group']", %{
          "group" => %{
            "name" => "Updated Category Name",
            "description" => category.description,
            "image_path" => category.image_path,
            "status" => "published"
          }
        })
        |> render_submit()

      assert html =~ "Category updated successfully!"
      assert html =~ "Updated Category Name"
    end

    test "can delete a category without goals", %{conn: conn} do
      # Create a category specifically for deletion
      {:ok, deletable} =
        Groups.create_group(%{
          name: "To Delete",
          description: "Will be deleted",
          image_path: "/images/delete.jpg",
          status: :published
        })

      {:ok, view, _html} = live(conn, ~p"/admin/categories")

      html =
        view
        |> element("button[phx-click='delete_group'][phx-value-id='#{deletable.id}']")
        |> render_click()

      assert html =~ "Category deleted successfully!"
      refute html =~ "To Delete"
    end

    test "cannot delete a category with goals", %{conn: conn, category: category} do
      # Create a goal in this category
      user = user_fixture()

      {:ok, _goal} =
        HeadsUp.Goals.create_goal(%{
          title: "Test Goal",
          group_id: category.id,
          user_id: user.id,
          target_date: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      {:ok, view, _html} = live(conn, ~p"/admin/categories")

      html =
        view
        |> element("button[phx-click='delete_group'][phx-value-id='#{category.id}']")
        |> render_click()

      assert html =~ "Cannot delete category"
      assert html =~ "has 1 goal(s) associated"
      assert html =~ category.name
    end
  end

  describe "Category table display" do
    setup %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)
      %{conn: conn}
    end

    test "shows status badge", %{conn: conn, category: category} do
      {:ok, _view, html} = live(conn, ~p"/admin/categories")

      assert html =~ "Published"
    end

    test "shows image thumbnail when available", %{conn: conn, category: category} do
      {:ok, _view, html} = live(conn, ~p"/admin/categories")

      assert html =~ category.image_path
    end

    test "shows edit and delete buttons", %{conn: conn, category: category} do
      {:ok, _view, html} = live(conn, ~p"/admin/categories")

      assert html =~ "Edit"
      assert html =~ "Delete"
    end

    test "shows Goals column with count", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin/categories")

      assert html =~ "Goals"
      assert html =~ ~r/\d+ goals?/
    end
  end
end
