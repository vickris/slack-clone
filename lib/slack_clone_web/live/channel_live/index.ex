defmodule SlackCloneWeb.ChannelLive.Index do
  use SlackCloneWeb, :live_view

  alias SlackClone.Chat
  alias SlackClone.Chat.Channel

  @impl true
  def mount(_params, %{"user_token" => user_token}, socket) do
    current_user = SlackClone.Accounts.get_user_by_session_token(user_token)
    channels = Chat.list_channels()

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> stream(:channels, channels)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Channel")
    |> assign(:channel, Chat.get_channel!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Channel")
    |> assign(:channel, %Channel{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Channels")
    |> assign(:channel, nil)
  end

  @impl true
  def handle_info({:saved, channel}, socket) do
    {:noreply, stream_insert(socket, :channels, channel)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    channel = Chat.get_channel!(id)
    {:ok, _} = Chat.delete_channel(channel)

    {:noreply, stream_delete(socket, :channels, channel)}
  end
end
