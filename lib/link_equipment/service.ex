defmodule LinkEquipment.Service do
  @moduledoc false

  @doc """
  The action the service performs.

  Is automatically wrapped in a transaction.
  """
  @callback run(keyword()) :: {:ok, any()} | {:error, any()}

  defmacro __using__(_opts \\ []) do
    behaviour = __MODULE__

    quote bind_quoted: [behaviour: behaviour] do
      @behaviour behaviour

      @before_compile behaviour

      defoverridable behaviour
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defoverridable(run: 1)

      def run(args) do
        LinkEquipment.Repo.transaction(super(args))
      end
    end
  end
end
