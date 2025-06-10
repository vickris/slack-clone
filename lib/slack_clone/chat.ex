defmodule SlackClone.Chat do
  import Ecto.Query, warn: false

  alias SlackClone.Chat.Channel
  alias SlackClone.Chat.Message
  alias SlackClone.Repo

  def list_channels do
    Repo.all(Channel)
  end

  def get_channel!(id) do
    Repo.get!(Channel, id)
  end

  def create_channel(attrs \\ %{}) do
    %Channel{}
    |> Channel.changeset(attrs)
    |> Repo.insert()
  end

  def list_channels_for_user(user) do
    user = Repo.preload(user, :channels)
    user.channels
  end

  def subscribe_to_channel_messages(channel_id) do
    Phoenix.PubSub.subscribe(SlackClone.PubSub, "channel:#{channel_id}")
  end

  def broadcast_new_message(channel_id, message) do
    Phoenix.PubSub.broadcast(
      SlackClone.PubSub,
      "channel:#{channel_id}",
      {:message_created, message}
    )
  end

  def create_message(attrs) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  def list_messages_paginated(channel_id, cursor \\ nil, limit \\ 10) do
    base_query =
      Message
      |> where(channel_id: ^channel_id)
      |> where([m], is_nil(m.thread_id))
      |> order_by([m], asc: m.inserted_at)
      |> preload([:user, replies: :user])

    paginated_query =
      case cursor do
        nil ->
          IO.puts("No cursor provided, fetching all messages====")
          base_query

        cursor ->
          base_query |> where([m], m.inserted_at > ^cursor)
      end

    messages = Repo.all(from m in paginated_query, limit: ^limit)

    next_cursor =
      case List.last(messages) do
        nil -> nil
        last_msg -> last_msg.inserted_at
      end

    IO.inspect({messages, next_cursor}, label: "Messages and Next Cursor")

    {messages, next_cursor}
  end

  def update_channel(%Channel{} = channel, attrs) do
    channel
    |> Channel.changeset(attrs)
    |> Repo.update()
  end

  def delete_channel(%Channel{} = channel) do
    Repo.delete(channel)
  end

  def change_channel(%Channel{} = channel) do
    Channel.changeset(channel, %{})
  end
end
