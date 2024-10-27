defmodule LinkEquipmentWeb.SourceLive do
  @moduledoc false
  use LinkEquipmentWeb, :live_view

  alias LinkEquipment.SourceManager
  alias LinkEquipmentWeb.RawLinkLiveComponent

  def mount(_params, _session, socket) do
    socket
    |> assign(source: nil)
    |> assign(raw_links: nil)
    |> ok()
  end

  def handle_params(%{"source" => url} = _params, _uri, socket) do
    socket =
      with {:ok, uri} <- URI.new(url),
           {:ok, uri} <- validate_as_remote_uri(uri) do
        assign_async(socket, [:source, :raw_links], fn -> get_source(URI.to_string(uri)) end)
      end

    noreply(socket)
  end

  defp get_source(url) do
    with {:ok, source} <- SourceManager.check_source(url) do
      base =
        url
        |> URI.parse()
        |> Map.put(:path, nil)
        |> Map.put(:query, nil)
        |> Map.put(:fragment, nil)
        |> URI.to_string()

      raw_links = source |> LinkEquipment.Lychee.extract_links() |> Enum.map(&Map.put(&1, :base, base))

      {:ok, %{source: source, raw_links: raw_links}}
    end
  end

  def render(assigns) do
    ~H"""
    <.cluster>
      <.living_source source={@source} />
      <.raw_links raw_links={@raw_links} />
    </.cluster>
    """
  end

  defp raw_links(assigns) do
    ~H"""
    <.async :let={raw_links} :if={@raw_links} assign={@raw_links}>
      <:loading></:loading>
      <.stack tag="ul">
        <li :for={raw_link <- raw_links}>
          <.live_component
            module={RawLinkLiveComponent}
            raw_link={raw_link}
            id={"#{:base64.encode(raw_link.text)}-#{raw_link.order}"}
          />
        </li>
      </.stack>
    </.async>
    """
  end

  defp living_source(assigns) do
    ~H"""
    <.async :let={source} :if={@source} assign={@source}>
      <:loading>
        <p>Getting source...</p>
      </:loading>
      <div id="living_source" phx-hook="LivingSource">
        <pre>
        <code id="basic_source">
    <%= source %>
        </code>
      </pre>
      </div>
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
