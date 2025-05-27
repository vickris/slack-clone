defmodule SlackCloneWeb.ChannelLive.FilePreview do
  use Phoenix.LiveComponent

  # Import the icon component so .icon is available in templates
  import SlackCloneWeb.CoreComponents

  @doc """
  Renders a file preview component with a link to download the file.
  """
  def render(assigns) do
    ~H"""
    <div class="border rounded-lg p-2">
      <% ext = Path.extname(@url) |> String.downcase() %>
      <%= case ext do %>
        <% ".jpg" <> _ -> %>
          <img src={@url} class="max-h-40 rounded" />
        <% ".png" <> _ -> %>
          <img src={@url} class="max-h-40 rounded" />
        <% ".pdf" -> %>
          <div class="flex items-center">
            <.icon name="hero-document-text" class="w-8 h-8 text-red-500" />
            <span class="ml-2">PDF Document</span>
          </div>
        <% _ -> %>
          <div class="flex items-center">
            <.icon name="hero-document" class="w-8 h-8 text-gray-500" />
            <span class="ml-2">File Attachment</span>
          </div>
      <% end %>
      <a href={@url} download class="text-sm text-blue-500 hover:underline mt-1 block">
        Download
      </a>
    </div>
    """
  end
end
