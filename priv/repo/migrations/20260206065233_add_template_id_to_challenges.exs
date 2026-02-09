defmodule HeadsUp.Repo.Migrations.AddTemplateIdToChallenges do
  use Ecto.Migration

  def change do
    alter table(:challenges) do
      # Reference to the template this challenge was created from
      add :template_id, references(:challenges, on_delete: :nilify_all)
    end

    create index(:challenges, [:template_id])
    create index(:challenges, [:is_template])
  end
end
