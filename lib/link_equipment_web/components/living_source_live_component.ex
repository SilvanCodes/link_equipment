defmodule LinkEquipmentWeb.LivingSourceLiveComponent do
  @moduledoc false
  use LinkEquipmentWeb, :live_component

  alias LinkEquipment.RawLink
  alias LinkEquipment.SourceManager
  alias LinkEquipment.StatusManager
  alias Phoenix.LiveView.AsyncResult

  attr :source_url, :string, required: true

  def mount(socket) do
    ok(socket)
  end

  @spec update(maybe_improper_list() | map(), any()) :: any()
  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> assign_source()
    |> ok()
  end

  defp assign_source(socket) do
    source_url_result =
      socket.assigns[:source_url]
      |> Option.wrap()
      |> Result.from_option()

    with {:ok, url} <- source_url_result,
         {:ok, uri} <- URI.new(url),
         {:ok, uri} <- RawLink.validate_as_http_uri(uri) do
      socket
      |> assign(:source, AsyncResult.loading())
      |> start_async(:get_source, fn -> get_source(URI.to_string(uri)) end)
    else
      {:error, error} ->
        assign(socket, :source, AsyncResult.failed(socket.assigns[:source] || AsyncResult.loading(), error))
    end
  end

  def handle_async(:get_source, {:ok, {:error, error}}, socket) do
    socket
    |> assign(:source, AsyncResult.failed(socket.assigns.source, {:error, error}))
    |> noreply()
  end

  def handle_async(:get_source, {:ok, {source, url}}, socket) do
    base =
      url
      |> URI.parse()
      |> Map.put(:path, nil)
      |> Map.put(:query, nil)
      |> Map.put(:fragment, nil)
      |> URI.to_string()

    raw_links =
      source
      |> LinkEquipment.Lychee.extract_links()
      |> Enum.map(&Map.put(&1, :base, base))
      |> Enum.map(&RawLink.html_representation/1)
      |> Enum.map_join("||", &Enum.join(&1, "|"))
      |> :base64.encode()

    socket
    |> assign(:source, AsyncResult.ok(socket.assigns.source, source))
    |> assign(:links_encoded, raw_links)
    |> noreply()
  end

  def handle_async(:get_source, {:exit, reason}, socket) do
    socket
    |> assign(:source, AsyncResult.failed(socket.assigns.source, {:exit, reason}))
    |> noreply()
  end

  def handle_async(order, {:ok, {:ok, status_results}}, socket) when is_integer(order) do
    socket
    |> push_event("update-link-status", status_results)
    |> noreply()
  end

  def handle_async(order, {:ok, {:error, status_results}}, socket) when is_integer(order) do
    socket
    |> push_event("update-link-status", status_results)
    |> noreply()
  end

  def handle_async(order, unhandeled, socket) when is_integer(order) do
    dbg(unhandeled)

    noreply(socket)
  end

  defp check_status(%{"text" => text, "order" => order, "base" => base}) do
    raw_link = struct(RawLink, %{text: text, order: order, base: base})

    if RawLink.http_or_https_url?(raw_link) do
      case StatusManager.check_status(RawLink.unvalidated_url(raw_link)) do
        {:ok, status} ->
          {:ok, %{status: status, text: text, order: order}}

        {:error, error} ->
          {:error, %{status: error, text: text, order: order}}
      end
    else
      {:error, %{status: :not_http_or_https, text: text, order: order}}
    end
  end

  def handle_event("link", %{"order" => order} = params, socket) do
    socket
    |> start_async(String.to_integer(order), fn -> check_status(params) end)
    |> noreply()
  end

  def render(assigns) do
    ~H"""
    <div>
      <.async :let={source} :if={@source} assign={@source}>
        <:loading>
          <p>Getting source...</p>
        </:loading>
        <div
          id="living_source"
          phx-hook="LivingSource"
          data-links={@links_encoded}
          data-target={@myself}
        >
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
    </div>
    """
  end

  defp get_source(url) do
    with {:ok, source} <- SourceManager.check_source(url) do
      {source, url}
    end
  end
end