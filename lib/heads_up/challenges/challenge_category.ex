defmodule HeadsUp.Challenges.ChallengeCategory do
  use Ecto.Schema
  import Ecto.Changeset

  alias HeadsUp.Challenges.Challenge

  schema "challenge_categories" do
    field :name, :string
    field :description, :string
    field :image_path, :string
    field :status, Ecto.Enum, values: [:active, :inactive], default: :active
    field :order, :integer, default: 0

    has_many :challenges, Challenge, foreign_key: :category_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :description, :image_path, :status, :order])
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:description, max: 500)
    |> unique_constraint(:name)
  end
end
