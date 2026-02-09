defmodule HeadsUp.Repo.Migrations.AddMoodToDailyCheckIns do
  use Ecto.Migration

  def change do
    alter table(:daily_check_ins) do
      add :mood, :string
    end
  end
end
