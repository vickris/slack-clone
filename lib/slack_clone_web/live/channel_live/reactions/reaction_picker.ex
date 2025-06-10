defmodule SlackCloneWeb.Live.ChannelLive.Reactions.ReactionPicker do
  use Phoenix.LiveComponent

  @emojis ["👍", "👎", "❤️", "🔥", "🎉", "😄", "😕", "🚀"]

  @impl true
  def render(assigns) do
    ~H"""
    <div class="absolute bg-white border rounded-lg shadow-lg p-2 z-10 grid grid-cols-4 gap-1">
      <%= for emoji <- emojis() do %>
        <button
          phx-click="add_reaction"
          phx-value-emoji={emoji}
          phx-value-message_id={@message_id}
          class="text-xl hover:bg-gray-100 p-1 rounded"
        >
          {emoji}
        </button>
      <% end %>
    </div>
    """
  end

  defp emojis do
    @emojis
  end
end
