defmodule HeadsUp.Repo.Migrations.AddLikeTypeToCheckInLikes do
  use Ecto.Migration

  def change do
    alter table(:check_in_likes) do
      add :like_type, :string, default: "like", null: false
    end
  end
end
