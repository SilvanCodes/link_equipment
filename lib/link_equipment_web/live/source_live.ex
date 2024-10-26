defmodule LinkEquipmentWeb.SourceLive do
  @moduledoc false
  use LinkEquipmentWeb, :live_view

  alias LinkEquipment.SourceManager

  def mount(_params, _session, socket) do
    socket
    |> assign(source: nil)
    |> ok()
  end

  def handle_params(%{"source" => url} = _params, _uri, socket) do
    socket =
      with {:ok, uri} <- URI.new(url),
           {:ok, uri} <- validate_as_remote_uri(uri) do
        assign_async(socket, :source, fn -> get_source(URI.to_string(uri)) end)
      end

    noreply(socket)
  end

  defp get_source(url) do
    with {:ok, source} <- SourceManager.check_source(url) do
      {:ok, %{source: source}}
    end
  end

  def render(assigns) do
    ~H"""
    <.async :let={source} :if={@source} assign={@source}>
      <:loading>
        <p>Getting source...</p>
      </:loading>
      <pre>
        <code>
    <%= source %>
        </code>
      </pre>
      <:failed :let={_failure}>
        <p>There was an error getting the source. :(</p>
      </:failed>
    </.async>
    """
  end

  defp validate_as_remote_uri(%URI{scheme: nil}), do: {:error, :scheme_missing}
  defp validate_as_remote_uri(%URI{scheme: ""}), do: {:error, :scheme_missing}
  defp validate_as_remote_uri(%URI{host: nil}), do: {:error, :host_missing}
  defp validate_as_remote_uri(%URI{host: ""}), do: {:error, :host_missing}
  defp validate_as_remote_uri(%URI{} = uri), do: {:ok, uri}
end