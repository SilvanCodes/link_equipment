defmodule Util do
  @moduledoc false
  alias Phoenix.LiveView.Socket

  defmodule Phoenix do
    @moduledoc false

    @spec noreply(Socket.t()) :: {:noreply, Socket.t()}
    def noreply(socket), do: {:noreply, socket}

    @spec reply(Socket.t(), map()) :: {:reply, map(), Socket.t()}
    def reply(socket, map), do: {:reply, map, socket}
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
