defmodule SlackClone.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  alias SlackClone.Accounts.User
  alias SlackClone.Chat.Channel

  schema "messages" do
    field :content, :string
    field :attachments, {:array, :string}
    belongs_to :user, User
    belongs_to :channel, Channel
    belongs_to :thread, __MODULE__
    has_many :replies, __MODULE__, foreign_key: :thread_id

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :user_id, :channel_id, :thread_id, :attachments])
    |> validate_length(:attachments, max: 3)
    |> validate_required([:content, :user_id, :channel_id])
  end
end
