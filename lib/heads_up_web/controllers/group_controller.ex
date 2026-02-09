defmodule HeadsUpWeb.GroupController do
  use HeadsUpWeb, :controller
  alias HeadsUp.GoalGroups

  def create(conn, %{"group" => group_params}) do
    case GoalGroups.create_group(group_params) do
      {:ok, group} ->
        json(conn, %{status: "ok", group: group})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{status: "error", errors: changeset.errors})
    end
  end
end
