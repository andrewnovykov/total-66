defmodule HeadsUpWeb.Api.CategoryController do
  use HeadsUpWeb, :controller

  alias HeadsUp.{GoalGroups, Group, Repo}

  action_fallback HeadsUpWeb.FallbackController

  # GET /api/categories - List all categories
  def index(conn, _params) do
    categories = GoalGroups.list_main_categories()

    conn
    |> put_status(:ok)
    |> render(:index, categories: categories)
  end

  # GET /api/categories/:id - Get specific category with subcategories
  def show(conn, %{"id" => id}) do
    case Integer.parse(id) do
      {category_id, _} ->
        case GoalGroups.get_group(category_id) do
          nil ->
            conn
            |> put_status(:not_found)
            |> render(:error, message: "Category not found")

          category ->
            category = Repo.preload(category, [:parent, :subcategories])

            conn
            |> put_status(:ok)
            |> render(:show, category: category)
        end

      :error ->
        conn
        |> put_status(:bad_request)
        |> render(:error, message: "Invalid category ID")
    end
  end

  # GET /api/categories/:id/subcategories - List subcategories of a category
  def subcategories(conn, %{"id" => id}) do
    case Integer.parse(id) do
      {category_id, _} ->
        subcategories = GoalGroups.list_subcategories(category_id)

        conn
        |> put_status(:ok)
        |> render(:index, categories: subcategories)

      :error ->
        conn
        |> put_status(:bad_request)
        |> render(:error, message: "Invalid category ID")
    end
  end

  # POST /api/admin/categories - Create new category (Admin only)
  def create(conn, %{"category" => category_params}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case GoalGroups.create_group_with_admin_check(category_params, current_user_id) do
        {:ok, category} ->
          category = Repo.preload(category, [:parent, :subcategories])

          conn
          |> put_status(:created)
          |> render(:show, category: category)

        {:error, :unauthorized} ->
          conn
          |> put_status(:forbidden)
          |> render(:error, message: "Admin access required")

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(:changeset_error, changeset: changeset)
      end
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "Authentication required")
    end
  end

  # PUT /api/admin/categories/:id - Update category (Admin only)
  def update(conn, %{"id" => id, "category" => category_params}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {category_id, _} ->
          case GoalGroups.get_group(category_id) do
            nil ->
              conn
              |> put_status(:not_found)
              |> render(:error, message: "Category not found")

            category ->
              case GoalGroups.update_group_with_admin_check(
                     category,
                     category_params,
                     current_user_id
                   ) do
                {:ok, updated_category} ->
                  updated_category = Repo.preload(updated_category, [:parent, :subcategories])

                  conn
                  |> put_status(:ok)
                  |> render(:show, category: updated_category)

                {:error, :unauthorized} ->
                  conn
                  |> put_status(:forbidden)
                  |> render(:error, message: "Admin access required")

                {:error, changeset} ->
                  conn
                  |> put_status(:unprocessable_entity)
                  |> render(:changeset_error, changeset: changeset)
              end
          end

        :error ->
          conn
          |> put_status(:bad_request)
          |> render(:error, message: "Invalid category ID")
      end
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "Authentication required")
    end
  end

  # DELETE /api/admin/categories/:id - Delete category (Admin only)
  def delete(conn, %{"id" => id}) do
    current_user_id = get_current_user_id(conn)

    if current_user_id do
      case Integer.parse(id) do
        {category_id, _} ->
          case GoalGroups.get_group(category_id) do
            nil ->
              conn
              |> put_status(:not_found)
              |> render(:error, message: "Category not found")

            category ->
              case GoalGroups.delete_group_with_admin_check(category, current_user_id) do
                {:ok, _deleted_category} ->
                  conn
                  |> put_status(:ok)
                  |> render(:delete, message: "Category deleted successfully")

                {:error, :unauthorized} ->
                  conn
                  |> put_status(:forbidden)
                  |> render(:error, message: "Admin access required")

                {:error, changeset} ->
                  conn
                  |> put_status(:unprocessable_entity)
                  |> render(:changeset_error, changeset: changeset)
              end
          end

        :error ->
          conn
          |> put_status(:bad_request)
          |> render(:error, message: "Invalid category ID")
      end
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "Authentication required")
    end
  end

  # Private helper functions

  defp get_current_user_id(conn) do
    case conn.assigns[:current_user] do
      %{id: user_id} -> user_id
      _ -> nil
    end
  end
end
