defmodule SlackCloneWeb.ChannelLive.Show do
  use SlackCloneWeb, :live_view

  alias SlackClone.Chat
  alias SlackClone.Chat.Message
  alias SlackClone.Repo
  alias SlackCloneWeb.Presence

  @page_size 5

  @impl true
  def mount(%{"id" => channel_id}, %{"user_token" => user_token}, socket) do
    current_user = SlackClone.Accounts.get_user_by_session_token(user_token)
    channel = Chat.get_channel!(channel_id)

    if authorized?(current_user, channel) do
      Presence.track(
        self(),
        "channel:#{channel_id}",
        current_user.id,
        %{
          username: current_user.username,
          user_id: current_user.id,
          online_at: System.system_time(:second)
        }
      )

      presences = Presence.list("channel:#{channel_id}")

      Chat.subscribe_to_channel_messages(channel_id)

      # Fetch paginated messages (most recent first)
      {messages, next_cursor} = Chat.list_messages_paginated(channel_id, nil, @page_size)

      socket =
        socket
        |> assign(:channel, channel)
        |> assign(:presences, presences)
        |> assign(:current_user, current_user)
        |> assign(:messages_cursor, next_cursor)
        |> stream_configure(:messages, dom_id: & &1.id)
        |> stream(:messages, messages)
        |> assign(:uploaded_files, [])
        |> allow_upload(:avatar,
          accept: ~w(.jpg .jpeg .png .pdf .doc .docx .xls .xlsx .txt),
          max_entries: 3,
          max_file_size: 10_000_000,
          auto_upload: true,
          external: &presign_upload/2,
          progress: &handle_progress/3
        )

      {:ok, socket}
    else
      {:ok, redirect(socket, to: ~p"/channels")}
    end
  end

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, :presences, Presence.list("channel:#{socket.assigns.channel.id}"))}
  end

  @impl true
  def handle_info({:message_created, message}, socket) do
    message_with_user = Repo.preload(message, [:user, :replies, reactions: :user])
    {:noreply, stream_insert(socket, :messages, Chat.to_stream_item(message_with_user))}
  end

  @impl true
  def handle_info({:reaction_added, %{id: message_id}}, socket) do
    message_with_reaction =
      Repo.get!(Message, message_id) |> Repo.preload([:user, :reactions, replies: :user])

    {:noreply, stream_insert(socket, :messages, Chat.to_stream_item(message_with_reaction))}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:channel, Chat.get_channel!(id))}
  end

  @impl true
  def handle_event("send_message", %{"content" => content}, socket) do
    current_user = socket.assigns.current_user
    channel = socket.assigns.channel

    {completed_uploads, _in_progress} = uploaded_entries(socket, :avatar)

    uploaded_files =
      if length(completed_uploads) > 0 do
        consume_uploaded_entries(socket, :avatar, fn %{key: key}, _entry ->
          {:ok, key}
        end)
      else
        []
      end

    case Chat.create_message(%{
           content: content,
           channel_id: channel.id,
           user_id: current_user.id,
           attachments: uploaded_files
         }) do
      {:ok, message} ->
        Chat.broadcast_new_message(channel.id, message)

        {:noreply,
         socket
         |> put_flash(:info, "Message sent!")
         |> push_event("reset-form", %{})}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:message_changeset, changeset)
         |> put_flash(:error, "Failed to send message.")}
    end
  end

  @impl true
  def handle_event("add_reaction", %{"emoji" => emoji, "message_id" => message_id}, socket) do
    IO.inspect({emoji, message_id}, label: "Adding Reaction===")
    current_user = socket.assigns.current_user

    case Chat.add_reaction(current_user.id, message_id, emoji) do
      {:ok, _reaction} ->
        # Broadcast the new reaction to the channel
        Chat.broadcast_reaction_added(socket.assigns.channel.id, %{
          id: message_id,
          reaction: %{emoji: emoji, user_id: current_user.id}
        })

        socket =
          socket
          |> assign(show_reaction_picker: nil)

        {:noreply, put_flash(socket, :info, "Reaction added!")}

      {:error, :already_reacted} ->
        {:noreply, put_flash(socket, :info, "You already reacted with this emoji.")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to add reaction: #{reason}")}
    end
  end

  @impl true
  def handle_event("toggle_reaction", %{"emoji" => emoji, "message_id" => message_id}, socket) do
    current_user = socket.assigns.current_user

    existing_reaction =
      Chat.get_reaction_by_user_and_message(current_user.id, message_id, emoji)

    case existing_reaction do
      nil ->
        # Add the reaction if it doesn't exist
        Chat.add_reaction(current_user.id, message_id, emoji)

      _ ->
        # Remove the reaction if it exists
        case Chat.remove_reaction(existing_reaction) do
          {:ok, _reaction} ->
            # Broadcast the reaction removal to the channel
            Chat.broadcast_reaction_added(socket.assigns.channel.id, %{
              id: message_id,
              reaction: %{emoji: emoji, user_id: current_user.id, removed: true}
            })

            {:noreply, put_flash(socket, :info, "Reaction removed!")}

          {:error, reason} ->
            {:noreply, put_flash(socket, :error, "Failed to remove reaction: #{reason}")}
        end
    end
  end

  @impl true
  def handle_event("validate", _unsigned_params, socket) do
    upload_errors =
      for {_error_id, msg} <- socket.assigns.uploads.avatar.errors || [] do
        error_to_string(msg)
      end

    socket =
      if length(upload_errors) > 0 do
        put_flash(socket, :error, Enum.join(upload_errors, ", "))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  @impl true
  def handle_event("load_more_messages", _params, socket) do
    channel_id = socket.assigns.channel.id
    cursor = socket.assigns.messages_cursor

    {messages, next_cursor} = Chat.list_messages_paginated(channel_id, cursor, @page_size)

    # Prepend older messages to the stream
    {:noreply,
     socket
     |> assign(:messages_cursor, next_cursor)
     |> stream(:messages, messages)}
  end

  defp page_title(:show), do: "Show Channel"
  defp page_title(:edit), do: "Edit Channel"

  defp authorized?(current_user, channel) do
    channel = Repo.preload(channel, :members)
    Enum.any?(channel.members, fn member -> member.id == current_user.id end)
  end

  defp handle_progress(:avatar, _entry, socket) do
    {:noreply, socket}
  end

  defp presign_upload(entry, socket) do
    IO.inspect(entry, label: "Presigning Upload Entry====")

    case SlackClone.Aws.S3Upload.generate_presigned_url(
           entry.client_name,
           entry.client_type
         ) do
      {:ok, upload_url, key} ->
        meta = %{key: key, upload_url: upload_url, uploader: "S3"}
        {:ok, meta, socket}

      {:error, reason} ->
        {:error, %{error: "Failed to generate S3 URL: #{reason}"}, socket}
    end
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(:external_client_failure), do: "Something went terribly wrong"
  defp error_to_string(:too_many_entries), do: "You have selected too many files"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
end
