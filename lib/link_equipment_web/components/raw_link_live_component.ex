defmodule LinkEquipmentWeb.RawLinkLiveComponent do
  @moduledoc false
  use LinkEquipmentWeb, :live_component

  alias Ecto.Changeset
  alias LinkEquipment.RawLink
  alias LinkEquipment.StatusManager
  alias Phoenix.LiveView.AsyncResult

  def mount(socket) do
    socket
    |> assign(:status, nil)
    |> ok()
  end

  def update(assigns, socket) do
    raw_link = assigns[:raw_link] || socket.assigns[:raw_link]

    socket
    |> assign(:status, AsyncResult.loading())
    |> start_async(:check_status, fn -> check_status(raw_link) end)
    |> assign(assigns)
    |> ok()
  end

  def handle_async(:check_status, {:ok, status}, socket) do
    LinkEquipment.Repo.update(Changeset.change(socket.assigns.raw_link, %{status: to_string(status)}))

    send(self(), {:raw_link_status_updated, nil})

    {:noreply, assign(socket, :status, AsyncResult.ok(socket.assigns.status, status))}
  end

  def handle_async(:check_status, {:exit, reason}, socket) do
    {:noreply, assign(socket, :status, AsyncResult.failed(socket.assigns.status, {:exit, reason}))}
  end

  def render(assigns) do
    data_attributes = data_attributes(assigns)

    ~H"""
    <div id={@id} phx-hook="LivingRawLink" {data_attributes}>
      <%= @raw_link.text %>
    </div>
    """
  end

  defp data_attributes(%{raw_link: raw_link, status: status}) do
    default_data = %{"data-order" => raw_link.order, "data-text" => raw_link.text}

    if status && status.ok? do
      Map.put(default_data, "data-status", status.result)
    else
      default_data
    end
  end

  defp check_status(raw_link) do
    if RawLink.http_or_https_url?(raw_link) do
      with {:ok, status} <- StatusManager.check_status(RawLink.unvalidated_url(raw_link)) do
        status
      end
    else
      :not_http_or_https
    end
  end
end
