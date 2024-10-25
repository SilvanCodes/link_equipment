defmodule LinkEquipmentWeb.HomeLive do
  @moduledoc false
  use LinkEquipmentWeb, :live_view

  alias LinkEquipmentWeb.LinkLiveComponent

  def mount(_params, _session, socket) do
    socket
    |> assign(form: to_form(%{}), results: nil)
    |> ok()
  end

  def handle_params(%{"url_input" => url_input} = _params, _uri, socket) do
    socket =
      with {:ok, uri} <- URI.new(url_input),
           {:ok, uri} <- validate_as_remote_uri(uri) do
        socket = assign(socket, :form, to_form(%{"url_input" => url_input}))

        if socket.assigns.live_action == :scan do
          assign_async(socket, :results, fn -> scan_url(URI.to_string(uri)) end)
        else
          socket
        end
      else
        {:error, error} ->
          assign(socket, :form, to_form(%{"url_input" => url_input}, errors: [url_input: {error, []}]))
      end

    noreply(socket)
  end

  def handle_params(_params, _uri, socket) do
    noreply(socket)
  end

  def handle_event("validate", params, socket) do
    socket
    |> push_patch(to: ~p"/?#{Map.take(params, ["url_input"])}", replace: true)
    |> noreply()
  end

  def handle_event("scan", params, socket) do
    socket
    |> push_patch(to: ~p"/scan?#{params}")
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
        <.form for={@form} phx-change="validate" phx-submit="scan">
          <.cluster>
            <.input type="text" field={@form[:url_input]} label="URL:" />
            <.button>Scan</.button>
          </.cluster>
        </.form>
      </.center>
      <.center>
        <%= cond do %>
          <% @results && @results.loading -> %>
            <p>Scanning...</p>
          <% results = @results && @results.ok? && @results.result -> %>
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
          <% true -> %>
            <p>Try entering a URL :)</p>
        <% end %>
      </.center>
    </.stack>
    """
  end

  defp scan_url(url) do
    with {:ok, results} <- LinkEquipment.Lychee.collect_links(url) do
      # We could group here if it turns out to be interesting when a resource is linked multiple times in different places.
      {:ok, %{results: results |> Enum.sort() |> Enum.uniq_by(& &1.url)}}
    end
  end

  defp validate_as_remote_uri(%URI{scheme: nil}), do: {:error, :scheme_missing}
  defp validate_as_remote_uri(%URI{scheme: ""}), do: {:error, :scheme_missing}
  defp validate_as_remote_uri(%URI{host: nil}), do: {:error, :host_missing}
  defp validate_as_remote_uri(%URI{host: ""}), do: {:error, :host_missing}
  defp validate_as_remote_uri(%URI{} = uri), do: {:ok, uri}
end
