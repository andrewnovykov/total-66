defmodule HeadsUpWeb.Api.ReportJSON do
  def show(%{report: report}) do
    %{data: report_data(report)}
  end

  def error(%{message: message}) do
    %{error: message}
  end

  def error(%{changeset: changeset}) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
          opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
        end)
      end)

    %{errors: errors}
  end

  defp report_data(report) do
    %{
      id: report.id,
      reason: report.reason,
      description: report.description,
      reported_user_id: report.reported_user_id,
      challenge_id: report.challenge_id,
      inserted_at: report.inserted_at
    }
  end
end
