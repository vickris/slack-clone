defmodule SlackClone.Chat.ChannelMembership do
  use Ecto.Schema
  import Ecto.Changeset

  schema "channel_memberships" do
    belongs_to :user, SlackClone.Accounts.User
    belongs_to :channel, SlackClone.Chat.Channel
    timestamps()
  end

  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:user_id, :channel_id])
    |> validate_required([:user_id, :channel_id])
    |> unique_constraint([:user_id, :channel_id])
  end
end
