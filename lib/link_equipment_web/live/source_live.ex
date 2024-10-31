defmodule LinkEquipmentWeb.SourceLive do
  @moduledoc false
  use LinkEquipmentWeb, :live_view

  alias LinkEquipment.RawLink
  alias LinkEquipment.SourceManager
  alias LinkEquipmentWeb.RawLinkLiveComponent
  alias Phoenix.LiveView.AsyncResult

  def mount(_params, _session, socket) do
    socket
    |> setup_raw_links_temporary_table()
    |> ok()
  end

  def handle_params(params, _uri, socket) do
    socket
    |> assign_params(params)
    |> assign_source()
    |> assign_raw_links()
    |> noreply()
  end

  defp assign_source(socket) do
    with {:ok, source_url} <- get_param_result(socket, :source_url),
         {:ok, uri} <- URI.new(source_url),
         {:ok, uri} <- validate_as_remote_uri(uri) do
      if socket.assigns[:source_url] == source_url do
        socket
      else
        socket
        |> assign(:source_url, source_url)
        |> assign(:source, AsyncResult.loading())
        |> start_async(:get_source, fn -> get_source(URI.to_string(uri)) end)
      end
    else
      {:error, error} ->
        socket
        |> add_param_error(:source_url, error)
        |> assign(:source, nil)
    end
  end

  def handle_info({:raw_link_status_updated, nil}, socket) do
    socket
    |> assign_raw_links()
    |> noreply()
  end

  defp assign_raw_links(socket) do
    case RawLink.list_raw_links(get_params(socket)) do
      {:ok, {raw_links, meta}} ->
        assign(socket, %{raw_links: raw_links, meta: meta})

      {:error, _meta} ->
        assign(socket, %{raw_links: nil, meta: nil})
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

    # could be done async
    LinkEquipment.Repo.delete_all(RawLink)
    raw_links = source |> LinkEquipment.Lychee.extract_links() |> Enum.map(&Map.put(&1, :base, base))
    LinkEquipment.Repo.insert_all(RawLink, Enum.map(raw_links, &Map.from_struct/1), on_conflict: :replace_all)

    socket
    |> assign(:source, AsyncResult.ok(socket.assigns.source, source))
    |> assign_raw_links()
    |> noreply()
  end

  def handle_async(:get_source, {:exit, reason}, socket) do
    socket
    |> assign(:source, AsyncResult.failed(socket.assigns.source, {:exit, reason}))
    |> noreply()
  end

  def handle_event("scan", params, socket) do
    params =
      params
      |> Map.take(["source_url"])
      |> merge_params(socket)

    socket
    |> push_patch(to: ~p"/source?#{params}", replace: true)
    |> noreply()
  end

  defp get_source(url) do
    with {:ok, source} <- SourceManager.check_source(url) do
      {source, url}
    end
  end

  def render(assigns) do
    ~H"""
    <.stack>
      <.center>
        <.form for={@params} phx-change="scan">
          <.input type="text" field={@params[:source_url]} label="URL:" />
        </.form>
      </.center>
      <.sidebar>
        <.raw_links :if={@raw_links} raw_links={@raw_links} meta={@meta} path={table_path(assigns)} />
        <.living_source source={@source} />
      </.sidebar>
    </.stack>
    """
  end

  defp table_path(assigns) do
    # prevent Flop from stacking its parameters in the url
    params = Map.drop(assigns.params.params, ["order_by", "order_directions"])
    ~p"/source?#{params}"
  end

  defp raw_links(assigns) do
    ~H"""
    <p>Result Count: <%= @meta.total_count %></p>
    <Flop.Phoenix.table items={@raw_links} meta={@meta} path={@path}>
      <:col :let={raw_link} label="Text" field={:text}>
        <.live_component
          module={RawLinkLiveComponent}
          raw_link={raw_link}
          id={"#{:base64.encode(raw_link.text)}-#{raw_link.order}"}
        />
      </:col>
      <:col :let={raw_link} label="Status" field={:status}><%= raw_link.status %></:col>
    </Flop.Phoenix.table>
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

  defp setup_raw_links_temporary_table(socket) do
    if is_nil(socket.assigns[:repo]) do
      repo = LinkEquipment.Repo.use_exclusive_connection_repo()
      LinkEquipment.RawLink.create_temporary_table()
      assign(socket, :repo, repo)
    else
      socket
    end
  end

  defp validate_as_remote_uri(%URI{scheme: nil}), do: {:error, :scheme_missing}
  defp validate_as_remote_uri(%URI{scheme: ""}), do: {:error, :scheme_missing}
  defp validate_as_remote_uri(%URI{host: nil}), do: {:error, :host_missing}
  defp validate_as_remote_uri(%URI{host: ""}), do: {:error, :host_missing}
  defp validate_as_remote_uri(%URI{} = uri), do: {:ok, uri}
end
