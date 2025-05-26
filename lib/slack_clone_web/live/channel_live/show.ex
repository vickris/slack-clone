defmodule SlackCloneWeb.ChannelLive.Show do
  use SlackCloneWeb, :live_view

  alias SlackClone.Chat
  alias SlackClone.Repo
  alias SlackCloneWeb.Presence

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

      # Get initial presence
      presences = Presence.list("channel:#{channel_id}")

      Chat.subscribe_to_channel_messages(channel_id)

      initial_messages =
        channel_id
        |> Chat.list_messages()

      socket =
        socket
        |> assign(:channel, channel)
        |> assign(:presences, presences)
        |> assign(:current_user, current_user)
        |> assign(:show_thread, nil)
        |> stream_configure(:messages, dom_id: &"message-#{&1.id}")
        |> stream(:messages, initial_messages)
        |> allow_upload(:avatar,
          accept: ~w(.jpg .jpeg .png),
          max_entries: 1,
          max_file_size: 5_000_000
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

  def handle_event("show_thread", %{"message-id" => message_id}, socket) do
    IO.inspect(socket.assigns.show_thread, label: "Current Show Thread ID")
    # Toggle thread visibility
    show_thread = if socket.assigns.show_thread, do: nil, else: message_id |> String.to_integer()
    IO.inspect(show_thread, label: "Show Thread ID")
    {:noreply, assign(socket, :show_thread, show_thread)}
  end

  @impl true
  def handle_event("send_message", %{"content" => text}, socket) do
    current_user = socket.assigns.current_user
    channel = socket.assigns.channel

    case Chat.create_message(channel, current_user, text) do
      {:ok, message} ->
        Chat.broadcast_new_message(channel.id, message)
        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :message_changeset, changeset)}
    end
  end

  defp page_title(:show), do: "Show Channel"
  defp page_title(:edit), do: "Edit Channel"

  defp authorized?(current_user, channel) do
    channel = Repo.preload(channel, :members)
    Enum.any?(channel.members, fn member -> member.id == current_user.id end)
  end
end
