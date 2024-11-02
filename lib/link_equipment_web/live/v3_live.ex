defmodule LinkEquipmentWeb.V3Live do
  @moduledoc false
  use LinkEquipmentWeb, :live_view

  alias LinkEquipmentWeb.LivingSourceLiveComponent

  def mount(_params, _session, socket) do
    ok(socket)
  end

  def handle_params(params, _uri, socket) do
    socket
    |> assign_params(params)
    |> noreply()
  end

  def handle_event("scan", params, socket) do
    params =
      params
      |> Map.take(["source_url"])
      |> merge_params(socket)

    socket
    |> push_patch(to: configured_path(params), replace: true)
    |> noreply()
  end

  defp configured_path(params), do: ~p"/v3?#{params}"

  def render(assigns) do
    ~H"""
    <.stack>
      <.center>
        <.form for={@params} phx-change="scan">
          <.input type="text" field={@params[:source_url]} label="URL:" />
        </.form>
      </.center>
      <.live_component
        if={@params[:source_url].value}
        id={:base64.encode(@params[:source_url].value)}
        module={LivingSourceLiveComponent}
        source_url={@params[:source_url].value}
      />
    </.stack>
    """
  end
end
