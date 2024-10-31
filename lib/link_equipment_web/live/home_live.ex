defmodule LinkEquipmentWeb.HomeLive do
  @moduledoc false
  use LinkEquipmentWeb, :live_view

  alias LinkEquipment.ScanManager
  alias LinkEquipmentWeb.LinkLiveComponent

  def mount(_params, _session, socket) do
    ok(socket)
  end

  def handle_params(params, _uri, socket) do
    socket = assign_params(socket, params)

    socket = assign_results(socket)

    noreply(socket)
  end

  def assign_results(socket) do
    with {:ok, url_input} <- get_param_result(socket, :url_input),
         {:ok, uri} <- URI.new(url_input),
         {:ok, uri} <- validate_as_remote_uri(uri) do
      assign_async(socket, :results, fn -> scan_url(URI.to_string(uri)) end)
    else
      {:error, error} ->
        socket |> assign(:results, nil) |> add_param_error(:url_input, error)
    end
  end

  def handle_event("validate", params, socket) do
    params = Map.take(params, ["url_input"])
    params = merged_params(params, socket)

    socket
    |> push_patch(to: ~p"/?#{params}", replace: true)
    |> noreply()
  end

  def handle_event("check_all", _params, socket) do
    Enum.each(
      socket.assigns.results.result,
      &send_update(LinkLiveComponent, id: :base64.encode(URI.to_string(&1.url)), check: true)
    )

    noreply(socket)
  end

  def render(assigns) do
    ~H"""
    <.stack>
      <.center>
        <.form for={@params} phx-change="validate" phx-submit="scan">
          <.cluster>
            <.input type="text" field={@params[:url_input]} label="URL:" />
          </.cluster>
        </.form>
      </.center>
      <.center>
        <.async :let={results} :if={@results} assign={@results}>
          <:loading>
            <p>Scanning...</p>
          </:loading>
          <.stack>
            <.cluster>
              <p>Last Results (<%= Enum.count(results) %>)</p>
              <.button phx-click="check_all">Check all</.button>
            </.cluster>

            <.stack tag="ul">
              <li :for={result <- results}>
                <.live_component
                  module={LinkLiveComponent}
                  id={:base64.encode(URI.to_string(result.url))}
                  link={result}
                />
              </li>
            </.stack>
          </.stack>
          <:failed :let={_failure}>
            <p>There was an error scanning the URL :(</p>
          </:failed>
        </.async>
      </.center>
    </.stack>
    """
  end

  defp scan_url(url) do
    with {:ok, results} <- ScanManager.check_scan(url) do
      {:ok, %{results: results}}
    end
  end

  defp validate_as_remote_uri(%URI{scheme: nil}), do: {:error, :scheme_missing}
  defp validate_as_remote_uri(%URI{scheme: ""}), do: {:error, :scheme_missing}
  defp validate_as_remote_uri(%URI{scheme: scheme}) when scheme not in ["http", "https"], do: {:error, :not_http_or_https}
  defp validate_as_remote_uri(%URI{host: nil}), do: {:error, :host_missing}
  defp validate_as_remote_uri(%URI{host: ""}), do: {:error, :host_missing}

  defp validate_as_remote_uri(%URI{host: host} = uri) do
    if String.contains?(host, ".") do
      {:ok, uri}
    else
      {:error, :missing_apex_domain}
    end
  end
end
