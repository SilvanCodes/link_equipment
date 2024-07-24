defmodule LinkEquipment.Factory do
  @moduledoc """
  Default entrypoint for constructing entities for tests.

  Expects the folllowing conventions:
  - Entities have an "<entity_module>.Repo" module
  - Entities have an "<entity_module>.Factory" module
  """

  @type entity :: struct()
  @type fields :: map()
  @type opts :: keyword()

  @callback build() :: entity()
  @callback build(fields()) :: entity()
  @callback build(fields(), opts()) :: entity()

  @callback insert() :: {:ok, entity()} | {:error, any()}
  @callback insert(fields()) :: {:ok, entity()} | {:error, any()}
  @callback insert(fields(), opts()) :: {:ok, entity()} | {:error, any()}

  @doc """
  Use to construct an entity in memory, dispatching to the "<entity_module>.Factory" build/0 function.
  """
  @spec build(module()) :: entity()
  def build(module), do: String.to_existing_atom("#{module}.Factory").build()

  @doc """
  Use to construct an entity in memory, dispatching to the "<entity_module>.Factory" build/1 function.
  """
  @spec build(module(), fields()) :: entity()
  def build(module, fields), do: String.to_existing_atom("#{module}.Factory").build(fields)

  @doc """
  Use to construct an entity in memory, dispatching to the "<entity_module>.Factory" build/2 function.
  """
  @spec build(module(), fields(), opts()) :: entity()
  def build(module, fields, opts), do: String.to_existing_atom("#{module}.Factory").build(fields, opts)

  @doc """
  Use to construct and persist an entity, dispatching to the "<entity_module>.Factory" insert/0 function.
  """
  @spec insert(module()) :: {:ok, entity()} | {:error, any()}
  def insert(module), do: String.to_existing_atom("#{module}.Factory").insert()

  @doc """
  Use to construct and persist an entity, dispatching to the "<entity_module>.Factory" insert/1 function.
  """
  @spec insert(module(), fields()) :: {:ok, entity()} | {:error, any()}
  def insert(module, fields), do: String.to_existing_atom("#{module}.Factory").insert(fields)

  @doc """
  Use to construct and persist an entity, dispatching to the "<entity_module>.Factory" insert/2 function.
  """
  @spec insert(module(), fields(), opts()) :: {:ok, entity()} | {:error, any()}
  def insert(module, fields, opts), do: String.to_existing_atom("#{module}.Factory").insert(fields, opts)

  defmacro __using__(_opts \\ []) do
    behaviour = __MODULE__

    quote bind_quoted: [behaviour: behaviour] do
      @behaviour behaviour

      alias LinkEquipment.Factory

      @entity __MODULE__ |> Atom.to_string() |> String.trim_trailing(".Factory") |> String.to_existing_atom()

      @entity_repo String.to_existing_atom("#{@entity}.Repo")

      def build, do: raise("build/0 not implemented in #{__MODULE__}")
      def build(fields), do: raise("build/1 not implemented in #{__MODULE__}")
      def build(fields, opts), do: raise("build/2 not implemented in #{__MODULE__}")

      def insert, do: @entity_repo.insert(build())
      def insert(fields), do: @entity_repo.insert(build(fields))
      def insert(fields, opts), do: @entity_repo.insert(build(fields, opts))

      defoverridable behaviour
    end
  end
end
