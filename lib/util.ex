defmodule Util do
  @moduledoc false
  alias Phoenix.Component
  alias Phoenix.LiveView.Socket

  defmodule Phoenix do
    @moduledoc false
    import Component, only: [assign: 3, to_form: 1, update: 3]

    alias Util.Result

    @type params :: %{String.t() => any()}

    @spec noreply(Socket.t()) :: {:noreply, Socket.t()}
    def noreply(socket), do: {:noreply, socket}

    @spec reply(Socket.t(), map()) :: {:reply, map(), Socket.t()}
    def reply(socket, map), do: {:reply, map, socket}

    @spec assign_params(Socket.t(), params()) :: Socket.t()
    def assign_params(socket, params) do
      assign(socket, :params, to_form(params))
    end

    @spec get_params(Socket.t()) :: params()
    def get_params(socket) do
      socket.assigns[:params].params
    end

    @spec get_param_result(Socket.t(), atom()) :: Result.t(any())
    def get_param_result(socket, key) do
      case get_param(socket, key) do
        nil ->
          {:error, :unset}

        value ->
          {:ok, value}
      end
    end

    @spec get_param(Socket.t(), atom()) :: any()
    def get_param(socket, key) do
      socket.assigns[:params][key].value
    end

    @spec merge_params(params(), Socket.t()) :: params()
    def merge_params(params, socket) do
      Map.merge(get_params(socket), params)
    end

    @spec add_param_error(Socket.t(), atom(), any()) :: Socket.t()
    def add_param_error(socket, key, error) do
      update(socket, :params, fn state ->
        Map.update(
          state,
          :errors,
          [{key, {error, []}}],
          &Keyword.put(&1, key, {error, []})
        )
      end)
    end
  end

  defmodule Option do
    @moduledoc false

    @type _some(type) :: [type]
    @type _none :: []

    @type t(type) :: _some(type) | _none()

    defguard is_some(option) when is_list(option) and length(option) == 1
    defguard is_none(option) when is_list(option) and option == []

    @spec wrap(any()) :: Option.t(any())
    def wrap(value), do: List.wrap(value)

    @spec unwrap(Option.t(any())) :: any()
    def unwrap([value]), do: value
    def unwrap([]), do: nil

    @spec map(Option.t(any()), function()) :: Option.t(any())
    def map(option, fun), do: Enum.map(option, fun)
  end

  defmodule Result do
    @moduledoc false
    import Util.Option

    @type success(type) :: {:ok, type}
    @type failure :: {:error, any()}

    @type t(type) :: success(type) | failure()

    @spec ok(any()) :: success(any())
    def ok(value), do: {:ok, value}

    @spec error(any()) :: failure()
    def error(value), do: {:error, value}

    @spec from_option(Option.t(any())) :: t(any())
    def from_option(option) when is_some(option), do: option |> unwrap() |> ok()
    def from_option(option) when is_none(option), do: option |> unwrap() |> error()
  end

  defmodule Validation do
    @moduledoc false

    @spec validate_as_remote_uri(URI.t()) :: Result.t(URI.t())
    def validate_as_remote_uri(uri)

    def validate_as_remote_uri(%URI{scheme: nil}), do: {:error, :scheme_missing}
    def validate_as_remote_uri(%URI{scheme: ""}), do: {:error, :scheme_missing}

    def validate_as_remote_uri(%URI{scheme: scheme}) when scheme not in ["http", "https"],
      do: {:error, :not_http_or_https}

    def validate_as_remote_uri(%URI{host: nil}), do: {:error, :host_missing}
    def validate_as_remote_uri(%URI{host: ""}), do: {:error, :host_missing}

    def validate_as_remote_uri(%URI{host: host} = uri) do
      if String.contains?(host, ".") do
        {:ok, uri}
      else
        {:error, :missing_apex_domain}
      end
    end
  end
end
