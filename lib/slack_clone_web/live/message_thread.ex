defmodule SlackCloneWeb.MessageThread do
  use Phoenix.Component

  def thread(assigns) do
    ~H"""
    <div class="ml-8 border-l-2 border-gray-200 pl-4">
      <%= for reply <- @replies do %>
        <div class="mb-2">
          <span class="text-sm font-medium">{reply.user.username}</span>
          <p class="text-sm">{reply.content}</p>
        </div>
      <% end %>
    </div>
    """
  end
end
