defmodule HeadsUpWeb.Api.CategoryAPITest do
  use HeadsUpWeb.ConnCase

  alias HeadsUp.{GoalGroups, Group, Repo}

  setup %{conn: conn} do
    # Create users with different roles
    admin_user = HeadsUp.AuthFixtures.user_fixture()
    regular_user = HeadsUp.AuthFixtures.user_fixture()

    # Update admin user to have admin role
    {:ok, admin_user} = HeadsUp.Accounts.update_user(admin_user, %{role: "admin"})

    # Create test categories
    {:ok, main_category} =
      GoalGroups.create_group(%{
        name: "Fitness",
        description: "Health and fitness goals",
        image_path: "/images/fitness.jpg",
        status: :published
      })

    {:ok, subcategory} =
      GoalGroups.create_group(%{
        name: "Weight Loss",
        description: "Goals related to losing weight",
        image_path: "/images/weight-loss.jpg",
        status: :published,
        parent_id: main_category.id
      })

    %{
      conn: conn,
      admin_user: admin_user,
      regular_user: regular_user,
      main_category: main_category,
      subcategory: subcategory
    }
  end

  describe "Public Category Access" do
    test "anyone can list main categories", %{conn: conn, main_category: main_category} do
      conn = get(conn, "/api/categories")
      response = json_response(conn, 200)

      assert is_list(response["data"])
      category_ids = Enum.map(response["data"], & &1["id"])
      assert main_category.id in category_ids

      # Should only show main categories (no parent_id)
      Enum.each(response["data"], fn category ->
        assert is_nil(category["parent_id"])
      end)
    end

    test "anyone can view a specific category with subcategories", %{
      conn: conn,
      main_category: main_category,
      subcategory: subcategory
    } do
      conn = get(conn, "/api/categories/#{main_category.id}")
      response = json_response(conn, 200)

      category_data = response["data"]
      assert category_data["id"] == main_category.id
      assert category_data["name"] == "Fitness"
      assert is_list(category_data["subcategories"])

      subcategory_ids = Enum.map(category_data["subcategories"], & &1["id"])
      assert subcategory.id in subcategory_ids
    end

    test "anyone can list subcategories of a category", %{
      conn: conn,
      main_category: main_category,
      subcategory: subcategory
    } do
      conn = get(conn, "/api/categories/#{main_category.id}/subcategories")
      response = json_response(conn, 200)

      assert is_list(response["data"])
      assert length(response["data"]) == 1
      assert List.first(response["data"])["id"] == subcategory.id
      assert List.first(response["data"])["parent_id"] == main_category.id
    end

    test "returns 404 for non-existent category", %{conn: conn} do
      conn = get(conn, "/api/categories/99999")
      assert json_response(conn, 404)["error"]["message"] == "Category not found"
    end

    test "returns 400 for invalid category ID", %{conn: conn} do
      conn = get(conn, "/api/categories/invalid-id")
      assert json_response(conn, 400)["error"]["message"] == "Invalid category ID"
    end
  end

  describe "Admin Category Creation" do
    test "admin can create main categories", %{conn: conn, admin_user: admin} do
      category_attrs = %{
        name: "Education",
        description: "Learning and skill development",
        image_path: "/images/education.jpg",
        status: "published"
      }

      conn =
        conn
        |> log_in_user(admin)
        |> post("/api/admin/categories", %{category: category_attrs})

      response = json_response(conn, 201)
      assert response["data"]["name"] == "Education"
      assert response["data"]["description"] == "Learning and skill development"
      assert is_nil(response["data"]["parent_id"])
      assert response["data"]["status"] == "published"
    end

    test "admin can create subcategories", %{conn: conn, admin_user: admin, main_category: parent} do
      subcategory_attrs = %{
        name: "Cardio",
        description: "Cardiovascular exercises",
        image_path: "/images/cardio.jpg",
        status: "published",
        parent_id: parent.id
      }

      conn =
        conn
        |> log_in_user(admin)
        |> post("/api/admin/categories", %{category: subcategory_attrs})

      response = json_response(conn, 201)
      assert response["data"]["name"] == "Cardio"
      assert response["data"]["parent_id"] == parent.id
      assert response["data"]["parent"]["id"] == parent.id
    end

    test "regular users cannot create categories", %{conn: conn, regular_user: user} do
      category_attrs = %{
        name: "Career",
        description: "Professional development",
        image_path: "/images/career.jpg",
        status: "published"
      }

      conn =
        conn
        |> log_in_user(user)
        |> post("/api/admin/categories", %{category: category_attrs})

      assert json_response(conn, 403)["error"]["message"] == "Admin access required"
    end

    test "unauthenticated users cannot create categories", %{conn: conn} do
      category_attrs = %{
        name: "Travel",
        description: "Travel goals",
        image_path: "/images/travel.jpg",
        status: "published"
      }

      conn = post(conn, "/api/admin/categories", %{category: category_attrs})
      assert json_response(conn, 401)["error"]["message"] == "Authentication required"
    end

    test "admin cannot create category with invalid data", %{conn: conn, admin_user: admin} do
      invalid_attrs = %{
        # Invalid: empty name
        name: "",
        description: "Test category"
      }

      conn =
        conn
        |> log_in_user(admin)
        |> post("/api/admin/categories", %{category: invalid_attrs})

      response = json_response(conn, 422)
      assert response["error"]["message"] == "Validation failed"
      assert response["success"] == false
    end
  end

  describe "Admin Category Updates" do
    test "admin can update categories", %{conn: conn, admin_user: admin, main_category: category} do
      update_attrs = %{
        name: "Health & Fitness",
        description: "Updated description for health and fitness"
      }

      conn =
        conn
        |> log_in_user(admin)
        |> put("/api/admin/categories/#{category.id}", %{category: update_attrs})

      response = json_response(conn, 200)
      assert response["data"]["name"] == "Health & Fitness"
      assert response["data"]["description"] == "Updated description for health and fitness"
      assert response["data"]["id"] == category.id
    end

    test "admin can convert category to subcategory", %{
      conn: conn,
      admin_user: admin,
      main_category: existing_category
    } do
      # Create another main category to be the parent
      {:ok, parent_category} =
        GoalGroups.create_group(%{
          name: "Wellness",
          description: "Overall wellness",
          image_path: "/images/wellness.jpg",
          status: :published
        })

      update_attrs = %{
        parent_id: parent_category.id
      }

      conn =
        conn
        |> log_in_user(admin)
        |> put("/api/admin/categories/#{existing_category.id}", %{category: update_attrs})

      response = json_response(conn, 200)
      assert response["data"]["parent_id"] == parent_category.id
      assert response["data"]["parent"]["id"] == parent_category.id
    end

    test "regular users cannot update categories", %{
      conn: conn,
      regular_user: user,
      main_category: category
    } do
      update_attrs = %{
        name: "Updated Name"
      }

      conn =
        conn
        |> log_in_user(user)
        |> put("/api/admin/categories/#{category.id}", %{category: update_attrs})

      assert json_response(conn, 403)["error"]["message"] == "Admin access required"
    end

    test "cannot update non-existent category", %{conn: conn, admin_user: admin} do
      update_attrs = %{
        name: "Updated Name"
      }

      conn =
        conn
        |> log_in_user(admin)
        |> put("/api/admin/categories/99999", %{category: update_attrs})

      assert json_response(conn, 404)["error"]["message"] == "Category not found"
    end
  end

  describe "Admin Category Deletion" do
    test "admin can delete categories without subcategories", %{
      conn: conn,
      admin_user: admin,
      subcategory: subcategory
    } do
      conn =
        conn
        |> log_in_user(admin)
        |> delete("/api/admin/categories/#{subcategory.id}")

      assert json_response(conn, 200)["message"] == "Category deleted successfully"

      # Verify category is deleted
      assert GoalGroups.get_group(subcategory.id) == nil
    end

    test "deleting parent category cascades to subcategories", %{
      conn: conn,
      admin_user: admin,
      main_category: main_category,
      subcategory: subcategory
    } do
      conn =
        conn
        |> log_in_user(admin)
        |> delete("/api/admin/categories/#{main_category.id}")

      assert json_response(conn, 200)["message"] == "Category deleted successfully"

      # Verify both categories are deleted due to cascade
      assert GoalGroups.get_group(main_category.id) == nil
      assert GoalGroups.get_group(subcategory.id) == nil
    end

    test "regular users cannot delete categories", %{
      conn: conn,
      regular_user: user,
      main_category: category
    } do
      conn =
        conn
        |> log_in_user(user)
        |> delete("/api/admin/categories/#{category.id}")

      assert json_response(conn, 403)["error"]["message"] == "Admin access required"
    end

    test "cannot delete non-existent category", %{conn: conn, admin_user: admin} do
      conn =
        conn
        |> log_in_user(admin)
        |> delete("/api/admin/categories/99999")

      assert json_response(conn, 404)["error"]["message"] == "Category not found"
    end
  end

  describe "Category Hierarchy" do
    test "creating deep subcategory hierarchy works", %{
      conn: conn,
      admin_user: admin,
      main_category: level1
    } do
      # Create level 2 subcategory
      level2_attrs = %{
        name: "Strength Training",
        description: "Muscle building exercises",
        image_path: "/images/strength.jpg",
        status: "published",
        parent_id: level1.id
      }

      conn_level2 =
        conn
        |> log_in_user(admin)
        |> post("/api/admin/categories", %{category: level2_attrs})

      level2_response = json_response(conn_level2, 201)
      level2_id = level2_response["data"]["id"]

      # Create level 3 subcategory
      level3_attrs = %{
        name: "Olympic Lifting",
        description: "Olympic weightlifting techniques",
        image_path: "/images/olympic.jpg",
        status: "published",
        parent_id: level2_id
      }

      conn_level3 =
        build_conn()
        |> log_in_user(admin)
        |> post("/api/admin/categories", %{category: level3_attrs})

      level3_response = json_response(conn_level3, 201)
      assert level3_response["data"]["parent_id"] == level2_id
      assert level3_response["data"]["parent"]["id"] == level2_id
    end

    test "listing subcategories shows correct hierarchy", %{
      conn: conn,
      admin_user: admin,
      main_category: parent
    } do
      # Create multiple subcategories
      {:ok, sub1} =
        GoalGroups.create_group(%{
          name: "Running",
          description: "Running goals",
          image_path: "/images/running.jpg",
          status: :published,
          parent_id: parent.id
        })

      {:ok, sub2} =
        GoalGroups.create_group(%{
          name: "Swimming",
          description: "Swimming goals",
          image_path: "/images/swimming.jpg",
          status: :published,
          parent_id: parent.id
        })

      conn = get(conn, "/api/categories/#{parent.id}/subcategories")
      response = json_response(conn, 200)

      # Original subcategory + 2 new ones
      assert length(response["data"]) == 3
      subcategory_names = Enum.map(response["data"], & &1["name"])
      assert "Running" in subcategory_names
      assert "Swimming" in subcategory_names
      # From setup
      assert "Weight Loss" in subcategory_names
    end
  end

  describe "Data Integrity" do
    test "API returns complete category data structure", %{conn: conn, main_category: category} do
      conn = get(conn, "/api/categories/#{category.id}")
      response = json_response(conn, 200)

      category_data = response["data"]

      # Check required fields are present
      assert is_integer(category_data["id"])
      assert is_binary(category_data["name"])
      assert is_binary(category_data["description"])
      assert is_binary(category_data["image_path"])
      assert category_data["status"] in ["published", "unpublished"]
      assert is_list(category_data["subcategories"])

      # Check timestamps
      assert category_data["created_at"]
      assert category_data["updated_at"]
    end

    test "subcategory includes parent information", %{conn: conn, subcategory: subcategory} do
      conn = get(conn, "/api/categories/#{subcategory.id}")
      response = json_response(conn, 200)

      category_data = response["data"]
      assert is_integer(category_data["parent_id"])
      assert is_map(category_data["parent"])
      assert category_data["parent"]["id"] == category_data["parent_id"]
    end
  end

  describe "Authorization Edge Cases" do
    test "admin role is properly checked", %{conn: conn, regular_user: user} do
      # Try to manually set role to admin in params (should not work)
      category_attrs = %{
        name: "Hacker Category",
        description: "This should not work",
        image_path: "/images/hack.jpg",
        status: "published"
      }

      conn =
        conn
        |> log_in_user(user)
        |> post("/api/admin/categories", %{category: category_attrs, role: "admin"})

      assert json_response(conn, 403)["error"]["message"] == "Admin access required"
    end

    test "admin can perform all CRUD operations", %{conn: conn, admin_user: admin} do
      # Create
      create_attrs = %{
        name: "Admin Test Category",
        description: "Testing admin capabilities",
        image_path: "/images/admin-test.jpg",
        status: "published"
      }

      conn_create =
        conn
        |> log_in_user(admin)
        |> post("/api/admin/categories", %{category: create_attrs})

      create_response = json_response(conn_create, 201)
      category_id = create_response["data"]["id"]

      # Update
      update_attrs = %{name: "Updated Admin Category"}

      conn_update =
        conn
        |> log_in_user(admin)
        |> put("/api/admin/categories/#{category_id}", %{category: update_attrs})

      update_response = json_response(conn_update, 200)
      assert update_response["data"]["name"] == "Updated Admin Category"

      # Delete
      conn_delete =
        conn
        |> log_in_user(admin)
        |> delete("/api/admin/categories/#{category_id}")

      assert json_response(conn_delete, 200)["message"] == "Category deleted successfully"
    end
  end
end
