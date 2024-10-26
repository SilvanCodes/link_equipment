defmodule LinkEquipment.RawLink do
  @moduledoc false

  use Ecto.Schema

  @timestamps_opts [type: :utc_datetime]

  @type t :: %__MODULE__{
          text: String.t(),
          element: String.t() | nil,
          attribute: String.t() | nil
        }

  embedded_schema do
    field :text, :string
    field :element, :string
    field :attribute, :string
  end
end
