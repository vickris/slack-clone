defmodule SlackCloneWeb.ChannelLive.Show do
  use SlackCloneWeb, :live_view

  alias SlackClone.Chat
  alias SlackClone.Repo
  alias SlackCloneWeb.Presence

  @page_size 20

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
        |> stream_configure(:messages, dom_id: &"message-#{&1.id}")
        |> stream(:messages, Enum.reverse(messages))
        |> assign(:uploaded_files, [])
        |> allow_upload(:avatar,
          accept: ~w(.jpg .jpeg .png .pdf .doc .docx .xls .xlsx .txt),
          max_entries: 3,
          max_file_size: 10_000_000,
          auto_upload: true,
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
    message_with_user = Repo.preload(message, [:user, :replies])
    {:noreply, stream_insert(socket, :messages, message_with_user)}
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
        consume_uploaded_entries(socket, :avatar, fn %{path: path}, entry ->
          dest = Path.join(["priv/static/uploads", "#{entry.uuid}-#{entry.client_name}"])
          File.mkdir_p!("priv/static/uploads")
          File.cp!(path, dest)
          {:ok, "/uploads/#{Path.basename(dest)}"}
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
        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :message_changeset, changeset)}
    end
  end

  def handle_event("validate", _unsigned_params, socket) do
    IO.inspect(socket.assigns.uploads.avatar, label: "Avatar Upload Entries")

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

  # Cursor pagination event
  @impl true
  def handle_event("load_more_messages", _params, socket) do
    channel_id = socket.assigns.channel.id
    cursor = socket.assigns.messages_cursor

    {messages, next_cursor} = Chat.list_messages_paginated(channel_id, cursor, @page_size)

    # Prepend older messages to the stream
    {:noreply,
     socket
     |> assign(:messages_cursor, next_cursor)
     |> stream(:messages, Enum.reverse(messages), at: 0)}
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

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(:external_client_failure), do: "Something went terribly wrong"
  defp error_to_string(:too_many_entries), do: "You have selected too many files"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
end
