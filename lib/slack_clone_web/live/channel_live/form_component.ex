defmodule SlackCloneWeb.ChannelLive.FormComponent do
  use SlackCloneWeb, :live_component

  import Phoenix.Component
  alias SlackClone.Chat

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage channel records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="channel-form"
        phx-target={@myself}
        phx-submit="save-channel"
        phx-change="validate"
      >
        <.input field={@form[:name]} label="Channel Name" />
        <.input field={@form[:description]} label="Description" />

        <:actions>
          <.button phx-disable-with="Saving...">Save Channel</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{channel: channel} = assigns, socket) do
    changeset = Chat.change_channel(channel)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate", %{"channel" => params}, socket) do
    changeset =
      socket.assigns.channel
      |> Chat.change_channel(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save-channel", %{"channel" => params}, socket) do
    # merge params with creator_id if it exists
    params = Map.put(params, "creator_id", socket.assigns.current_user.id)
    IO.inspect(params, label: "Params in save_channel")

    save_channel(socket, socket.assigns.action, params)
  end

  defp save_channel(socket, :edit, params) do
    case Chat.update_channel(socket.assigns.channel, params) do
      {:ok, channel} ->
        send(self(), {:saved, channel})

        {:noreply,
         socket
         |> put_flash(:info, "Channel updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_channel(socket, :new, params) do
    case Chat.create_channel(params) do
      {:ok, channel} ->
        send(self(), {:saved, channel})

        {:noreply,
         socket
         |> put_flash(:info, "Channel created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, changeset} ->
        IO.inspect(changeset, label: "Error creating channel")
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
