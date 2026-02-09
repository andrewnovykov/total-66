defmodule HeadsUpWeb.Api.CategoryJSON do
  alias HeadsUp.Group

  def index(%{categories: categories}) do
    %{
      data: Enum.map(categories, &render_category/1)
    }
  end

  def show(%{category: category}) do
    %{
      data: render_category_detailed(category)
    }
  end

  def delete(%{message: message}) do
    %{
      success: true,
      message: message
    }
  end

  def error(%{message: message}) do
    %{
      success: false,
      error: %{
        message: message
      }
    }
  end

  def changeset_error(%{changeset: changeset}) do
    %{
      success: false,
      error: %{
        message: "Validation failed",
        details: transform_errors(changeset)
      }
    }
  end

  defp render_category(%Group{} = category) do
    %{
      id: category.id,
      name: category.name,
      description: category.description,
      image_path: category.image_path,
      status: category.status,
      parent_id: category.parent_id,
      created_at: category.inserted_at,
      updated_at: category.updated_at
    }
  end

  defp render_category_detailed(%Group{} = category) do
    base_category = render_category(category)

    base_category
    |> Map.put(:parent, if(category.parent, do: render_category(category.parent), else: nil))
    |> Map.put(:subcategories, Enum.map(category.subcategories || [], &render_category/1))
  end

  defp transform_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
