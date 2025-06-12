defmodule SlackClone.Chat.Channel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "channels" do
    field :name, :string
    field :description, :string
    belongs_to :creator, SlackClone.Accounts.User
    has_many :memberships, SlackClone.Chat.ChannelMembership
    has_many :members, through: [:memberships, :user]

    timestamps()
  end

  def changeset(channel, attrs) do
    channel
    |> cast(attrs, [:name, :description, :creator_id])
    |> validate_required([:name, :creator_id, :description])
    |> validate_length(:name, min: 1, max: 50)
    |> validate_length(:description, max: 200)
    |> foreign_key_constraint(:creator_id)
    |> unique_constraint(:name)
  end
end
