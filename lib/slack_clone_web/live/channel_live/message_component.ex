defmodule SlackCloneWeb.MessageComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div id={@id} class="p-4 bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow">
      <div class="flex items-start space-x-3">
        <div class="flex-shrink-0 w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
          <span class="text-blue-600 font-medium text-sm">
            {String.at(@message.user.username, 0) |> String.upcase()}
          </span>
        </div>
        <div class="flex-1 min-w-0">
          <div class="flex items-baseline space-x-2">
            <span class="font-medium text-gray-900">{@message.user.username}</span>
            <span class="text-xs text-gray-500">
              {Timex.format!(@message.inserted_at, "{h12}:{m} {AM}")}
            </span>
          </div>
          <p class="mt-1 text-gray-800">{@message.content}</p>
          <%= if @message.attachments && length(@message.attachments) > 0 do %>
            <div class="mt-2 space-y-2">
              <%= for attachment <- @message.attachments do %>
                <.live_component
                  module={SlackCloneWeb.ChannelLive.FilePreview}
                  id={"file-preview-#{attachment}"}
                  class="bg-gray-50 p-2 rounded"
                  phx-hook="FilePreview"
                  url={"/uploads/#{Path.basename(attachment)}"}
                />
              <% end %>
            </div>
          <% end %>
          <!-- Thread controls -->
          <div class="mt-2 flex space-x-3 text-xs text-gray-500">
            <button
              phx-click="toggle_thread"
              phx-target={@myself}
              class="hover:text-blue-500 hover:underline"
            >
              <%= if @message.replies && length(@message.replies) > 0 do %>
                {length(@message.replies)} replies
              <% else %>
                Reply
              <% end %>
              <span class="ml-2">
                {if @show_thread, do: "(Hide Thread)", else: "(Show Thread)"}
              </span>
            </button>
          </div>
          <%= if @show_thread do %>
            <.live_component
              module={SlackCloneWeb.ChannelLive.MessageThread}
              id={"thread-#{@message.id}"}
              replies={@message.replies || []}
            />
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns) |> assign_new(:show_thread, fn -> false end)}
  end

  def handle_event("toggle_thread", _params, socket) do
    {:noreply, update(socket, :show_thread, &(!&1))}
  end
end
