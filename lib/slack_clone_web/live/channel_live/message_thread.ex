defmodule SlackCloneWeb.ChannelLive.MessageThread do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div class="ml-8 border-l-2 border-gray-200 pl-4 mt-2 space-y-2">
      <%= for reply <- @replies do %>
        <div class="text-sm p-2 bg-gray-50 rounded">
          <span class="font-medium text-gray-700">{reply.user.username}</span>
          <p class="text-gray-600">{reply.content}</p>
        </div>
      <% end %>
    </div>
    """
  end
end
