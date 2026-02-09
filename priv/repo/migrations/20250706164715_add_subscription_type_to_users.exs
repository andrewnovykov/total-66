defmodule HeadsUp.Repo.Migrations.AddSubscriptionTypeToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :subscription_type, :string, default: "free"
    end
  end
end
