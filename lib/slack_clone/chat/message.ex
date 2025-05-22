defmodule SlackClone.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  alias SlackClone.Accounts.User
  alias SlackClone.Chat.Channel

  schema "messages" do
    field :content, :string
    belongs_to :user, User
    belongs_to :channel, Channel

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :user_id, :channel_id])
    |> validate_required([:content, :user_id, :channel_id])
  end
end
