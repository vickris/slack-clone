defmodule SlackCloneWeb.ChannelLive.Show do
  use SlackCloneWeb, :live_view

  alias SlackClone.Chat
  alias SlackClone.Repo

  @impl true
  def mount(%{"id" => channel_id}, %{"user_token" => user_token}, socket) do
    current_user = SlackClone.Accounts.get_user_by_session_token(user_token)
    channel = Chat.get_channel!(channel_id)

    if authorized?(current_user, channel) do
      Chat.subscribe_to_channel_messages(channel_id)

      messages = Chat.list_messages(channel_id)

      socket =
        socket
        |> assign(:channel, channel)
        |> assign(:current_user, current_user)
        |> assign(:messages, messages)

      # |> stream_configure(:messages, dom_id: &"message-#{&1.id}")

      {:ok, socket}
    else
      {:ok, redirect(socket, to: ~p"/channels")}
    end
  end

  @impl true
  def handle_info({:message_created, message}, socket) do
    message_with_user = Repo.preload(message, :user)

    # update message stream
    {:noreply,
     update(socket, :messages, fn messages ->
       messages ++ [message_with_user]
     end)}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:channel, Chat.get_channel!(id))}
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
