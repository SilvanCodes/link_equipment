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

    @type success :: {:ok, any()}
    @type failure :: {:error, any()}

    @type t :: success() | failure()

    @spec ok(any()) :: success()
    def ok(value), do: {:ok, value}

    @spec error(any()) :: failure()
    def error(value), do: {:error, value}
  end

  defmodule Option do
    @moduledoc false

    @type _some :: [any()]
    @type _none :: []

    @type t :: _some() | _none()

    @spec wrap(any()) :: Option.t()
    def wrap(value), do: List.wrap(value)

    @spec unwrap(Option.t()) :: any()
    def unwrap([value]), do: value
    def unwrap([]), do: nil

    @spec map(Option.t(), function()) :: Option.t()
    def map(option, fun), do: Enum.map(option, fun)
  end
end
