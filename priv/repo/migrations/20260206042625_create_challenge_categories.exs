defmodule HeadsUp.Repo.Migrations.CreateChallengeCategories do
  use Ecto.Migration

  # No-op: Challenge categories have been removed.
  # The tables are dropped in 20260209120000_remove_categories_phases_add_task_type.exs
  def change do
  end
end
