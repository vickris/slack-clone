defmodule SlackCloneWeb.ChannelLive.FormComponent do
  use SlackCloneWeb, :live_component

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
        phx-change="validate"
        phx-submit="save"
      >
        <:actions>
          <.button phx-disable-with="Saving...">Save Channel</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{channel: channel} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Chat.change_channel(channel))
     end)}
  end

  # @impl true
  # def handle_event("validate", %{"channel" => channel_params}, socket) do
  #   changeset = Chat.change_channel(socket.assigns.channel, channel_params)
  #   {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  # end

  def handle_event("save", %{"channel" => channel_params}, socket) do
    save_channel(socket, socket.assigns.action, channel_params)
  end

  defp save_channel(socket, :edit, channel_params) do
    case Chat.update_channel(socket.assigns.channel, channel_params) do
      {:ok, channel} ->
        notify_parent({:saved, channel})

        {:noreply,
         socket
         |> put_flash(:info, "Channel updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_channel(socket, :new, channel_params) do
    case Chat.create_channel(channel_params) do
      {:ok, channel} ->
        notify_parent({:saved, channel})

        {:noreply,
         socket
         |> put_flash(:info, "Channel created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
