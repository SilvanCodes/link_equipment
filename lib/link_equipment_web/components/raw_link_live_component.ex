defmodule LinkEquipmentWeb.RawLinkLiveComponent do
  @moduledoc false
  use LinkEquipmentWeb, :live_component

  alias LinkEquipment.RawLink
  alias LinkEquipment.StatusManager

  def mount(socket) do
    socket
    |> assign(:status, nil)
    |> ok()
  end

  def update(assigns, socket) do
    raw_link = assigns[:raw_link] || socket.assigns[:raw_link]

    socket
    |> assign_async(:status, fn -> check_status(raw_link) end)
    |> assign(assigns)
    |> ok()
  end

  def render(assigns) do
    data_attributes = data_attributes(assigns)

    ~H"""
    <div id={@id} phx-hook="LivingRawLink" raw_link {data_attributes}>
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
        {:ok, %{status: status}}
      end
    else
      {:ok, %{status: :not_http_or_https}}
    end
  end
end
