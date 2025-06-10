defmodule SlackCloneWeb.ChannelLive.Reactions.ReactionsComponent do
  use Phoenix.LiveComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mt-1 flex flex-wrap gap-1">
      <%= for {emoji, users} <- group_reactions(@reactions) do %>
        <button
          phx-click="toggle_reaction"
          phx-value-emoji={emoji}
          phx-value-message_id={@message_id}
          class="px-2 py-0.5 bg-gray-100 rounded-full text-sm flex items-center space-x-1 hover:bg-gray-200"
        >
          <span>{emoji}</span>
          <span class="text-xs">{length(users)}</span>
        </button>
      <% end %>
      <button
        phx-click="show_reaction_picker"
        phx-value-message_id={@message_id}
        class="text-gray-400 hover:text-gray-600 text-xs px-1"
        phx-target={"#message-#{@message_id}"}
      >
        +
      </button>
    </div>
    """
  end

  defp group_reactions(reactions) do
    reactions
    |> Enum.group_by(& &1.emoji)
    |> Enum.map(fn {emoji, reactions} -> {emoji, Enum.map(reactions, & &1.user)} end)
  end
end
