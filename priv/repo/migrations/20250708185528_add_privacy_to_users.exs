defmodule HeadsUp.Repo.Migrations.AddPrivacyToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :privacy, :string, default: "public"
    end

    # Create an index for privacy field for performance
    create index(:users, [:privacy])
  end
end
