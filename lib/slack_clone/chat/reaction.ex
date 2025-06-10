defmodule SlackClone.Chat.Reaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "reactions" do
    field :emoji, :string
    belongs_to :message, SlackClone.Chat.Message
    belongs_to :user, SlackClone.Accounts.User

    timestamps()
  end

  def changeset(reaction, attrs) do
    reaction
    |> cast(attrs, [:emoji, :message_id, :user_id])
    |> validate_required([:emoji, :message_id, :user_id])
    |> unique_constraint([:user_id, :message_id, :emoji],
      name: :unique_reaction_per_user_per_message
    )
    |> foreign_key_constraint(:message_id)
    |> foreign_key_constraint(:user_id)
  end
end
