defmodule LinkEquipmentWeb.SourceLive do
  @moduledoc false
  use LinkEquipmentWeb, :live_view

  alias LinkEquipment.RawLink
  alias LinkEquipment.SourceManager
  alias LinkEquipmentWeb.RawLinkLiveComponent
  alias Phoenix.LiveView.AsyncResult

  def mount(_params, _session, socket) do
    socket =
      if is_nil(socket.assigns[:repo]) do
        repo = LinkEquipment.Repo.use_private_connection_repo()
        LinkEquipment.RawLink.create_temporary_table()
        assign(socket, :repo, repo)
      else
        socket
      end

    socket
    |> assign(:form, to_form(%{}))
    |> assign(:source, nil)
    |> assign(:raw_links, [])
    |> ok()
  end

  def handle_params(%{"source" => url_input} = params, _uri, socket) do
    socket =
      with {:ok, uri} <- URI.new(url_input),
           {:ok, uri} <- validate_as_remote_uri(uri) do
        socket = assign(socket, :form, to_form(%{"source" => url_input}))

        if socket.assigns.live_action == :scan do
          socket
          |> assign(:source, AsyncResult.loading())
          |> start_async(:get_source, fn -> get_source(URI.to_string(uri)) end)
        else
          socket
        end
      else
        {:error, error} ->
          assign(socket, :form, to_form(%{"source" => url_input}, errors: [source: {error, []}]))
      end

    socket = update_raw_links_list(socket, params)

    noreply(socket)
  end

  def handle_params(_params, _uri, socket) do
    noreply(socket)
  end

  defp update_raw_links_list(socket, params) do
    case RawLink.list_raw_links(params) do
      {:ok, {raw_links, meta}} ->
        assign(socket, %{raw_links_list: raw_links, meta: meta})

      {:error, _meta} ->
        socket
    end
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
    raw_links = source |> LinkEquipment.Lychee.extract_links() |> Enum.map(&Map.put(&1, :base, base))
    LinkEquipment.Repo.insert_all(RawLink, Enum.map(raw_links, &Map.from_struct/1))

    socket = update_raw_links_list(socket, %{})

    {:noreply, assign(socket, :source, AsyncResult.ok(socket.assigns.source, source))}
  end

  def handle_async(:get_source, {:exit, reason}, socket) do
    {:noreply, assign(socket, :org, AsyncResult.failed(socket.assigns.source, {:exit, reason}))}
  end

  def handle_event("validate", params, socket) do
    socket
    |> push_patch(to: ~p"/source?#{Map.take(params, ["source"])}", replace: true)
    |> noreply()
  end

  def handle_event("scan", params, socket) do
    socket
    |> push_patch(to: ~p"/source/scan?#{params}")
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
        <.form for={@form} phx-change="validate" phx-submit="scan">
          <.cluster>
            <.input type="text" field={@form[:source]} label="URL:" />
            <.button>Scan</.button>
          </.cluster>
        </.form>
      </.center>
      <.sidebar>
        <.raw_links raw_links={@raw_links} />
        <.living_source source={@source} />
      </.sidebar>
    </.stack>
    """
  end

  defp raw_links(assigns) do
    ~H"""
    <.stack tag="ul" id="raw_links_list">
      <li :for={raw_link <- @raw_links}>
        <.live_component
          module={RawLinkLiveComponent}
          raw_link={raw_link}
          id={"#{:base64.encode(raw_link.text)}-#{raw_link.order}"}
        />
      </li>
    </.stack>
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
