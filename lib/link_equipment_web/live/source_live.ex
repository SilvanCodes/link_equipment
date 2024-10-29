defmodule LinkEquipmentWeb.SourceLive do
  @moduledoc false
  use LinkEquipmentWeb, :live_view

  alias LinkEquipment.SourceManager
  alias LinkEquipmentWeb.RawLinkLiveComponent

  def mount(_params, _session, socket) do
    socket
    |> assign(:form, to_form(%{}))
    |> assign(:source, nil)
    |> assign(:raw_links, nil)
    |> ok()
  end

  def handle_params(%{"source" => url_input} = _params, _uri, socket) do
    socket =
      with {:ok, uri} <- URI.new(url_input),
           {:ok, uri} <- validate_as_remote_uri(uri) do
        socket = assign(socket, :form, to_form(%{"source" => url_input}))

        if socket.assigns.live_action == :scan do
          assign_async(socket, [:source, :raw_links], fn -> get_source(URI.to_string(uri)) end)
        else
          socket
        end
      else
        {:error, error} ->
          assign(socket, :form, to_form(%{"source" => url_input}, errors: [source: {error, []}]))
      end

    noreply(socket)
  end

  def handle_params(_params, _uri, socket) do
    noreply(socket)
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

  # NEXT: make this Flop table via inmemory SQlite db for nice querying and sorting
  # maybe introduce separate in-memory repo for this
  # will be awesome !!!
  defp raw_links(assigns) do
    ~H"""
    <.async :let={raw_links} :if={@raw_links} assign={@raw_links}>
      <:loading></:loading>
      <.stack tag="ul" id="raw_links_list">
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

  defp setup_inmemory_table(opts) do
    table_name = Keyword.get(opts, :table_name)

    """
    CREATE TEMPORARY TABLE #{table_name}(
      "text" TEXT PRIMARY KEY,
      "order" INTEGER NOT NULL,
      "element" TEXT,
      "attribute" TEXT,
      "base" TEXT
    );
    """
  end

  def get_temp_table_connection(opts) do
    {:ok, repo} =
      LinkEquipment.Repo.start_link(
        name: nil,
        temp_store: :memory,
        pool_size: 1
      )

    # This call is per process, i.e. scoped to the live view.
    LinkEquipment.Repo.put_dynamic_repo(repo)

    table_name = Keyword.get(opts, :table_name)

    sql = """
    CREATE TEMPORARY TABLE #{table_name}(
      "text" TEXT PRIMARY KEY,
      "order" INTEGER NOT NULL,
      "element" TEXT,
      "attribute" TEXT,
      "base" TEXT
    );
    """

    LinkEquipment.Repo.query(sql)

    # do this somewhere in cleanup hook
    # Supervisor.stop(repo)
  end
end
