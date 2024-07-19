defmodule LinkEquipment.Repo do
  use Ecto.Repo,
    otp_app: :link_equipment,
    adapter: Ecto.Adapters.SQLite3
end
