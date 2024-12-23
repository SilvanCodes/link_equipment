defmodule LinkEquipment.Repo do
  use Ecto.Repo,
    otp_app: :link_equipment,
    adapter: Ecto.Adapters.SQLite3

  def meta do
    query("select * from sqlite_master")
  end

  @spec use_exclusive_connection_repo() :: pid()
  def use_exclusive_connection_repo do
    {:ok, repo} =
      start_link(
        name: nil,
        temp_store: :memory,
        pool_size: 1
      )

    # This call is per process, i.e. scoped to the live view.
    put_dynamic_repo(repo)

    # do this somewhere in cleanup hook
    # Supervisor.stop(repo)
    repo
  end

  defmodule EctoURI do
    @moduledoc false
    use Ecto.Type

    def type, do: :map

    # Provide custom casting rules.
    # Cast strings into the URI struct to be used at runtime
    def cast(uri) when is_binary(uri) do
      {:ok, URI.parse(uri)}
    end

    # Accept casting of URI structs as well
    def cast(%URI{} = uri), do: {:ok, uri}

    # Everything else is a failure though
    def cast(_), do: :error

    # When loading data from the database, as long as it's a map,
    # we just put the data back into a URI struct to be stored in
    # the loaded schema struct.
    def load(data) when is_map(data) do
      data =
        for {key, val} <- data do
          {String.to_existing_atom(key), val}
        end

      {:ok, struct!(URI, data)}
    end

    # When dumping data to the database, we *expect* a URI struct
    # but any value could be inserted into the schema struct at runtime,
    # so we need to guard against them.
    def dump(%URI{} = uri), do: {:ok, Map.from_struct(uri)}
    def dump(_), do: :error
  end
end
