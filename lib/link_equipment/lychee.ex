defmodule LinkEquipment.Lychee do
  @moduledoc false
  use Rustler,
    otp_app: :link_equipment,
    crate: :linkequipment_lychee

  # When your NIF is loaded, it will override this function.
  def collect_links(_url), do: :erlang.nif_error(:nif_not_loaded)
end
