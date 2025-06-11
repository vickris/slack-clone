defmodule SlackClone.Chat do
  import Ecto.Query, warn: false

  alias SlackClone.Chat.Channel
  alias SlackClone.Chat.Message
  alias SlackClone.Chat.Reaction
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

  def broadcast_reaction_added(channel_id, reaction) do
    Phoenix.PubSub.broadcast(
      SlackClone.PubSub,
      "channel:#{channel_id}",
      {:reaction_added, reaction}
    )
  end

  def create_message(attrs) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  def get_reaction_by_user_and_message(user_id, message_id, emoji) do
    Reaction
    |> where(user_id: ^user_id, message_id: ^message_id, emoji: ^emoji)
    |> Repo.one()
  end

  def list_messages_paginated(channel_id, cursor \\ nil, limit \\ 10) do
    base_query =
      Message
      |> where(channel_id: ^channel_id)
      |> where([m], is_nil(m.thread_id))
      |> order_by([m], asc: m.inserted_at)
      |> preload([:user, :reactions, replies: :user])

    paginated_query =
      case cursor do
        nil ->
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

    grouped =
      messages
      |> Enum.group_by(&NaiveDateTime.to_date(&1.inserted_at))

    interleaved =
      grouped
      |> Enum.sort_by(fn {date, _} -> date end)
      |> Enum.flat_map(fn {date, msgs} ->
        [{:date, date}] ++ msgs
      end)
      |> Enum.map(fn
        {:date, date} -> to_stream_item({:date, date})
        msg -> to_stream_item(msg)
      end)

    {interleaved, next_cursor}
  end

  def to_stream_item(%Message{} = msg), do: %{id: "msg-#{msg.id}", type: :message, message: msg}
  def to_stream_item({:date, date}), do: %{id: "date-#{date}", type: :date, date: date}

  def add_reaction(user_id, message_id, emoji) do
    IO.puts("Adding reaction: #{emoji} to message ID: #{message_id} by user ID: #{user_id}")

    %Reaction{}
    |> Reaction.changeset(%{message_id: message_id, user_id: user_id, emoji: emoji})
    |> Repo.insert()
  end

  def remove_reaction(%Reaction{} = reaction) do
    Repo.delete(reaction)
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
