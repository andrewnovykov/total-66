defmodule HeadsUp.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :content, :string
    field :read, :boolean, default: false

    belongs_to :conversation, HeadsUp.Conversation
    belongs_to :sender, HeadsUp.Users

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :read, :conversation_id, :sender_id])
    |> validate_required([:content, :conversation_id, :sender_id])
    |> validate_length(:content, min: 1, max: 5000)
    |> foreign_key_constraint(:conversation_id)
    |> foreign_key_constraint(:sender_id)
  end
end
