defmodule LinkEquipment.RawLink do
  @moduledoc false

  use Ecto.Schema

  alias Util.Option

  @timestamps_opts [type: :utc_datetime]

  @type t :: %__MODULE__{
          text: String.t(),
          element: Option.t(String.t()),
          attribute: Option.t(String.t()),
          order: integer(),
          base: Option.t(String.t()),
          status: Option.t(String.t())
        }

  @derive {
    Flop.Schema,
    filterable: [:text, :status], sortable: [:text, :status], default_limit: 9999
  }

  @primary_key {:order, :integer, autogenerate: false}

  schema "raw_links" do
    field :text, :string
    field :element, :string
    field :attribute, :string
    field :base, :string
    field :status, :string
  end

  def list_raw_links(params) do
    Flop.validate_and_run(__MODULE__, params, for: __MODULE__)
  end

  def create_temporary_table do
    sql = """
    CREATE TEMPORARY TABLE raw_links(
      "text" TEXT,
      "element" TEXT,
      "attribute" TEXT,
      "order" INTEGER PRIMARY KEY,
      "base" TEXT,
      "status" TEXT
    );
    """

    LinkEquipment.Repo.query(sql)
  end

  @spec unvalidated_url(LinkEquipment.RawLink.t()) :: binary()
  def unvalidated_url(%__MODULE__{text: text, base: base}) do
    if String.starts_with?(text, "/") do
      base <> text
    else
      text
    end
  end

  @spec http_or_https_url?(LinkEquipment.RawLink.t()) :: boolean()
  def http_or_https_url?(%__MODULE__{} = raw_link) do
    match?({:ok, _}, validate_as_http_uri(raw_link))
  end

  defp validate_as_http_uri(%__MODULE__{} = raw_link) do
    with {:ok, uri} <- URI.new(unvalidated_url(raw_link)) do
      validate_as_http_uri(uri)
    end
  end

  defp validate_as_http_uri(%URI{scheme: nil}), do: {:error, :scheme_missing}
  defp validate_as_http_uri(%URI{scheme: ""}), do: {:error, :scheme_missing}
  defp validate_as_http_uri(%URI{host: nil}), do: {:error, :host_missing}
  defp validate_as_http_uri(%URI{host: ""}), do: {:error, :host_missing}
  defp validate_as_http_uri(%URI{scheme: scheme} = uri) when scheme in ["http", "https"], do: {:ok, uri}
  defp validate_as_http_uri(%URI{}), do: {:error, :not_http_or_https}
end
