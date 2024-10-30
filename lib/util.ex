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

    @spec get_param(Socket.t(), atom()) :: Result.t(any())
    def get_param(socket, key) do
      case socket.assigns[:params][key].value do
        nil ->
          {:error, :unset}

        value ->
          {:ok, value}
      end
    end

    @spec merged_params(params(), Socket.t()) :: params()
    def merged_params(params, socket) do
      Map.merge(socket.assigns.params.params, params)
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

  defmodule Result do
    @moduledoc false

    @type success(type) :: {:ok, type}
    @type failure :: {:error, any()}

    @type t(type) :: success(type) | failure()

    @spec ok(any()) :: success(any())
    def ok(value), do: {:ok, value}

    @spec error(any()) :: failure()
    def error(value), do: {:error, value}
  end

  defmodule Option do
    @moduledoc false

    @type _some(type) :: [type]
    @type _none :: []

    @type t(type) :: _some(type) | _none()

    @spec wrap(any()) :: Option.t(any())
    def wrap(value), do: List.wrap(value)

    @spec unwrap(Option.t(any())) :: any()
    def unwrap([value]), do: value
    def unwrap([]), do: nil

    @spec map(Option.t(any()), function()) :: Option.t(any())
    def map(option, fun), do: Enum.map(option, fun)
  end
end
