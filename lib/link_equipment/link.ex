defmodule LinkEquipment.Link do
  @moduledoc false

  use Ecto.Schema

  alias Ecto.Changeset

  @timestamps_opts [type: :utc_datetime]

  @type t :: %__MODULE__{
          url: URI,
          source_document_url: URI,
          html_element: String.t() | nil,
          element_attribute: String.t() | nil
        }

  schema "links" do
    field :url, :map
    field :source_document_url, :map
    field :html_element, :string
    field :element_attribute, :string

    timestamps()
  end

  def changeset(link \\ %__MODULE__{}, params \\ %{}) do
    link
    |> Changeset.cast(params, [:url, :source_document_url, :html_element, :element_attribute])
    |> Changeset.validate_required([:url, :source_document_url])
  end
end
