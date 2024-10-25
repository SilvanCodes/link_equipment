defmodule LinkEquipmentWeb.LinkLiveComponent do
  @moduledoc false
  use LinkEquipmentWeb, :live_component

  def mount(socket) do
    socket
    |> assign(status: nil)
    |> ok()
  end

  def update(assigns, socket) do
    socket =
      if assigns[:check] && socket.assigns.link.url.scheme in ["http", "https"] do
        url = URI.to_string(socket.assigns.link.url)

        assign_async(socket, :status, fn -> check_status(url) end)
      else
        assign(socket, assigns)
      end

    ok(socket)
  end

  def handle_event("scan", params, socket) do
    socket
    |> push_patch(to: ~p"/scan?#{Map.take(params, ["url_input"])}")
    |> noreply()
  end

  def handle_event("check", _params, socket) do
    send_update(__MODULE__, id: socket.assigns.id, check: true)

    noreply(socket)
  end

  def render(assigns) do
    ~H"""
    <div>
      <.box style={status_border_color(@status)}>
        <.cluster>
          <p><%= @link.url %></p>
          <.cluster :if={@link.url.scheme in ["http", "https"]}>
            <.button
              phx-click={JS.push("scan", value: %{"url_input" => URI.to_string(@link.url)})}
              phx-target={@myself}
            >
              Scan
            </.button>

            <.link href={URI.to_string(@link.url)} target="_blank">
              <.button>Open</.button>
            </.link>

            <.status status={@status} target={@myself} />
          </.cluster>
        </.cluster>
      </.box>
    </div>
    """
  end

  defp status(assigns) do
    ~H"""
    <%= cond do %>
      <% @status == nil -> %>
        <.button phx-click="check" phx-target={@target}>
          Check
        </.button>
      <% @status.loading -> %>
        Checking...
      <% @status.ok? -> %>
        <%= @status.result %>
    <% end %>
    """
  end

  defp check_status(url) do
    with {:ok, response} <- Req.head(url) do
      {:ok, %{status: response.status}}
    end
  end

  defp status_border_color(status) do
    cond do
      status == nil -> "border-color: black"
      status.loading -> "border-color: gray"
      status.result in 200..299 -> "border-color: green"
      status.result in 300..399 -> "border-color: yellow"
      status.result in 400..599 -> "border-color: red"
    end
  end
end
