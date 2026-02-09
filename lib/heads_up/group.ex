defmodule HeadsUp.Group do
  use Ecto.Schema
  import Ecto.Changeset

  schema "groups" do
    field :name, :string
    field :status, Ecto.Enum, values: [:published, :unpublished]
    field :description, :string
    field :image_path, :string

    belongs_to :parent, __MODULE__, foreign_key: :parent_id
    has_many :subcategories, __MODULE__, foreign_key: :parent_id
    has_many :goals, HeadsUp.Goal

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(group, attrs) do
    group
    |> cast(attrs, [:name, :description, :image_path, :status, :parent_id])
    |> validate_required([:name, :description, :image_path, :status])
    |> foreign_key_constraint(:parent_id)
    |> validate_not_self_parent()
  end

  defp validate_not_self_parent(changeset) do
    parent_id = get_field(changeset, :parent_id)
    group_id = get_field(changeset, :id)

    if parent_id && group_id && parent_id == group_id do
      add_error(changeset, :parent_id, "cannot be parent of itself")
    else
      changeset
    end
  end
end
