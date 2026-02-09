defmodule HeadsUpWeb.Api.RoleAuthorizationAPITest do
  @moduledoc """
  Tests for role-based API authorization.

  Verifies that:
  - Regular users can access user-level endpoints
  - Coach users have the same API access as regular users (no special API privileges)
  - Admin users can access admin-only endpoints
  - Coach users CANNOT access admin-only endpoints
  """
  use HeadsUpWeb.ConnCase

  alias HeadsUp.GoalGroups

  import HeadsUp.AuthFixtures

  setup %{conn: conn} do
    # Create users with different roles
    regular_user = user_fixture()
    coach_user = coach_fixture()
    admin_user = admin_fixture()

    # Create a test category for testing
    {:ok, category} =
      GoalGroups.create_group(%{
        name: "Test Category",
        description: "A test category",
        image_path: "/images/test.jpg",
        status: :published
      })

    %{
      conn: conn,
      regular_user: regular_user,
      coach_user: coach_user,
      admin_user: admin_user,
      category: category
    }
  end

  describe "Admin-only API endpoints - Category Create" do
    @category_attrs %{
      name: "New Category",
      description: "Test description",
      image_path: "/images/new.jpg",
      status: "published"
    }

    test "admin user can create categories", %{conn: conn, admin_user: admin} do
      conn =
        conn
        |> log_in_user(admin)
        |> post("/api/admin/categories", %{category: @category_attrs})

      assert json_response(conn, 201)["data"]["name"] == "New Category"
    end

    test "coach user CANNOT create categories (coach != admin)", %{conn: conn, coach_user: coach} do
      conn =
        conn
        |> log_in_user(coach)
        |> post("/api/admin/categories", %{category: @category_attrs})

      response = json_response(conn, 403)
      assert response["error"]["message"] == "Admin access required"
    end

    test "regular user CANNOT create categories", %{conn: conn, regular_user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> post("/api/admin/categories", %{category: @category_attrs})

      response = json_response(conn, 403)
      assert response["error"]["message"] == "Admin access required"
    end

    test "unauthenticated user CANNOT create categories", %{conn: conn} do
      conn = post(conn, "/api/admin/categories", %{category: @category_attrs})

      response = json_response(conn, 401)
      assert response["error"]["message"] == "Authentication required"
    end
  end

  describe "Admin-only API endpoints - Category Update" do
    @update_attrs %{name: "Updated Category Name"}

    test "admin user can update categories", %{conn: conn, admin_user: admin, category: category} do
      conn =
        conn
        |> log_in_user(admin)
        |> put("/api/admin/categories/#{category.id}", %{category: @update_attrs})

      assert json_response(conn, 200)["data"]["name"] == "Updated Category Name"
    end

    test "coach user CANNOT update categories", %{
      conn: conn,
      coach_user: coach,
      category: category
    } do
      conn =
        conn
        |> log_in_user(coach)
        |> put("/api/admin/categories/#{category.id}", %{category: @update_attrs})

      response = json_response(conn, 403)
      assert response["error"]["message"] == "Admin access required"
    end

    test "regular user CANNOT update categories", %{
      conn: conn,
      regular_user: user,
      category: category
    } do
      conn =
        conn
        |> log_in_user(user)
        |> put("/api/admin/categories/#{category.id}", %{category: @update_attrs})

      response = json_response(conn, 403)
      assert response["error"]["message"] == "Admin access required"
    end
  end

  describe "Admin-only API endpoints - Category Delete" do
    test "admin user can delete categories", %{conn: conn, admin_user: admin} do
      # Create a category specifically for this test
      {:ok, category_to_delete} =
        GoalGroups.create_group(%{
          name: "To Be Deleted",
          description: "Will be deleted",
          image_path: "/images/delete.jpg",
          status: :published
        })

      conn =
        conn
        |> log_in_user(admin)
        |> delete("/api/admin/categories/#{category_to_delete.id}")

      assert json_response(conn, 200)["message"] == "Category deleted successfully"
    end

    test "coach user CANNOT delete categories", %{
      conn: conn,
      coach_user: coach,
      category: category
    } do
      conn =
        conn
        |> log_in_user(coach)
        |> delete("/api/admin/categories/#{category.id}")

      response = json_response(conn, 403)
      assert response["error"]["message"] == "Admin access required"
    end

    test "regular user CANNOT delete categories", %{
      conn: conn,
      regular_user: user,
      category: category
    } do
      conn =
        conn
        |> log_in_user(user)
        |> delete("/api/admin/categories/#{category.id}")

      response = json_response(conn, 403)
      assert response["error"]["message"] == "Admin access required"
    end
  end

  describe "Public API endpoints - all roles can access" do
    test "regular user can view categories", %{conn: conn, regular_user: user, category: category} do
      conn =
        conn
        |> log_in_user(user)
        |> get("/api/categories/#{category.id}")

      response = json_response(conn, 200)
      assert response["data"]["id"] == category.id
    end

    test "coach user can view categories", %{conn: conn, coach_user: coach, category: category} do
      conn =
        conn
        |> log_in_user(coach)
        |> get("/api/categories/#{category.id}")

      response = json_response(conn, 200)
      assert response["data"]["id"] == category.id
    end

    test "admin user can view categories", %{conn: conn, admin_user: admin, category: category} do
      conn =
        conn
        |> log_in_user(admin)
        |> get("/api/categories/#{category.id}")

      response = json_response(conn, 200)
      assert response["data"]["id"] == category.id
    end

    test "unauthenticated user can view categories", %{conn: conn, category: category} do
      conn = get(conn, "/api/categories/#{category.id}")

      response = json_response(conn, 200)
      assert response["data"]["id"] == category.id
    end

    test "all roles can list categories", %{
      conn: conn,
      regular_user: user,
      coach_user: coach,
      admin_user: admin
    } do
      # Regular user
      conn1 = conn |> log_in_user(user) |> get("/api/categories")
      assert json_response(conn1, 200)["data"]

      # Coach user
      conn2 = build_conn() |> log_in_user(coach) |> get("/api/categories")
      assert json_response(conn2, 200)["data"]

      # Admin user
      conn3 = build_conn() |> log_in_user(admin) |> get("/api/categories")
      assert json_response(conn3, 200)["data"]

      # Unauthenticated
      conn4 = build_conn() |> get("/api/categories")
      assert json_response(conn4, 200)["data"]
    end
  end

  describe "Authenticated API endpoints - user, coach, and admin can access" do
    test "regular user can access authenticated endpoints", %{conn: conn, regular_user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> get("/api/goals/my")

      # Should return 200 with user's goals (even if empty)
      assert conn.status == 200
    end

    test "coach user can access authenticated endpoints", %{conn: conn, coach_user: coach} do
      conn =
        conn
        |> log_in_user(coach)
        |> get("/api/goals/my")

      assert conn.status == 200
    end

    test "admin user can access authenticated endpoints", %{conn: conn, admin_user: admin} do
      conn =
        conn
        |> log_in_user(admin)
        |> get("/api/goals/my")

      assert conn.status == 200
    end

    test "unauthenticated user CANNOT access authenticated endpoints", %{conn: conn} do
      conn = get(conn, "/api/goals/my")

      response = json_response(conn, 401)
      assert response["error"]["message"] == "Authentication required"
    end
  end

  describe "Role hierarchy verification" do
    test "coach role does not grant admin privileges", %{conn: conn, coach_user: coach} do
      # Coach should NOT be able to access admin endpoints
      category_attrs = %{
        name: "Coach Attempted Category",
        description: "Should fail",
        image_path: "/images/fail.jpg",
        status: "published"
      }

      conn =
        conn
        |> log_in_user(coach)
        |> post("/api/admin/categories", %{category: category_attrs})

      assert conn.status == 403
      assert json_response(conn, 403)["error"]["message"] == "Admin access required"
    end

    test "admin has highest privileges", %{conn: conn, admin_user: admin} do
      # Admin should be able to access everything
      category_attrs = %{
        name: "Admin Category",
        description: "Should succeed",
        image_path: "/images/success.jpg",
        status: "published"
      }

      conn =
        conn
        |> log_in_user(admin)
        |> post("/api/admin/categories", %{category: category_attrs})

      assert conn.status == 201
    end

    test "all roles have equal access to regular authenticated endpoints", %{
      conn: conn,
      regular_user: user,
      coach_user: coach,
      admin_user: admin
    } do
      # Test feed endpoint for all roles
      for {role_user, role_name} <- [{user, "user"}, {coach, "coach"}, {admin, "admin"}] do
        test_conn =
          build_conn()
          |> log_in_user(role_user)
          |> get("/api/feed")

        assert test_conn.status == 200,
               "#{role_name} should be able to access /api/feed but got status #{test_conn.status}"
      end
    end
  end
end
