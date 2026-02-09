defmodule HeadsUpWeb.FallbackController do
  use HeadsUpWeb, :controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(json: HeadsUpWeb.Api.GoalJSON)
    |> render(:error, message: "Resource not found")
  end

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: HeadsUpWeb.Api.GoalJSON)
    |> render(:changeset_error, changeset: changeset)
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(json: HeadsUpWeb.Api.GoalJSON)
    |> render(:error, message: "Unauthorized")
  end

  def call(conn, {:error, message}) when is_binary(message) do
    conn
    |> put_status(:internal_server_error)
    |> put_view(json: HeadsUpWeb.Api.GoalJSON)
    |> render(:error, message: message)
  end

  def call(conn, _error) do
    conn
    |> put_status(:internal_server_error)
    |> put_view(json: HeadsUpWeb.Api.GoalJSON)
    |> render(:error, message: "Internal server error")
  end
end
