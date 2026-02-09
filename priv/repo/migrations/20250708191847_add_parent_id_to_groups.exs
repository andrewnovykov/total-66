defmodule HeadsUp.Repo.Migrations.AddParentIdToGroups do
  use Ecto.Migration

  def change do
    alter table(:groups) do
      add :parent_id, references(:groups, on_delete: :delete_all), null: true
    end

    # Create an index for parent_id for performance
    create index(:groups, [:parent_id])
  end
end
