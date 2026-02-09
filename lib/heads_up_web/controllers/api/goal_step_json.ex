defmodule HeadsUpWeb.Api.GoalStepJSON do
  def index(%{steps: steps}) do
    %{data: Enum.map(steps, &render_step/1)}
  end

  def show(%{step: step}) do
    %{data: render_step(step)}
  end

  def action_success(%{message: message}) do
    %{success: true, message: message}
  end

  def error(%{message: message}) do
    %{success: false, error: %{message: message}}
  end

  def changeset_error(%{changeset: changeset}) do
    %{
      success: false,
      error: %{
        message: "Validation failed",
        details: translate_errors(changeset)
      }
    }
  end

  defp render_step(step) do
    %{
      id: step.id,
      title: step.title,
      completed: step.completed,
      order: step.order,
      goal_id: step.goal_id,
      created_at: step.inserted_at,
      updated_at: step.updated_at
    }
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
