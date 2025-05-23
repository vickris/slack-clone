defmodule SlackCloneWeb.Presence do
  @moduledoc """
  Handles presence tracking for users in the SlackClone application.
  """

  use Phoenix.Presence,
    otp_app: :slack_clone,
    pubsub_server: SlackClone.PubSub

  @doc """
  Tracks a user when they join a channel.

  ## Parameters
    - `socket`: The socket of the user joining the channel.
    - `topic`: The topic of the channel being joined.
    - `user_id`: The ID of the user joining the channel.
  """
  def track_user(socket, topic, user_id) do
    track(socket, topic, user_id, %{
      online_at: inspect(System.system_time(:second))
    })
  end

  # I want to subcribe to the channel presence
  @doc """
  Subscribes to the presence of users in a channel.
  ## Parameters
    - `topic`: The topic of the channel to subscribe to.
  """
  def subscribe(topic) do
    Phoenix.PubSub.subscribe(SlackClone.PubSub, topic)
  end
end
