defmodule LinkEquipment.Lychee do
  use Rustler,
    otp_app: :link_equipment,
    crate: :linkequipment_lychee

  # When your NIF is loaded, it will override this function.
  def collect_links(_url), do: :erlang.nif_error(:nif_not_loaded)

  defmodule Link do
    defstruct [
      :url,
      :source,
      :element,
      :attribute
    ]
  end
end
