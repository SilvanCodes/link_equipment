defmodule LinkEquipmentWeb.Components do
  @moduledoc false
  defdelegate living_source(assigns), to: LinkEquipmentWeb.LivingSourceComponent, as: :render
end
