defmodule SlackCloneWeb.OnlineUsersInChannel do
  @moduledoc """
  This module provides functionality to track online users in a channel.
  """

  use SlackCloneWeb, :channel
  alias SlackCloneWeb.Presence

  def join(_topic_name, _params, socket) do
    IO.inspect(socket.assigns.current_user, label: "Current User in OnlineUsersInChannel")
    send(self(), :after_join)
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    IO.inspect("After join event triggered", label: "After Join Event")
    channel_id = socket.assigns.channel.id
    current_user = socket.assigns.current_user

    {:ok, _} =
      Presence.track(socket, "channel:#{channel_id}", %{
        username: current_user.username,
        user_id: current_user.id,
        online_at: System.system_time(:second)
      })

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end
end
