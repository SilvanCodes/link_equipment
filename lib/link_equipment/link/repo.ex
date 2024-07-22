defmodule LinkEquipment.Link.Repo do
  alias Ecto.Changeset
  alias LinkEquipment.Link

  @spec insert(Link.t() | Changeset.t()) :: {:ok, Link.t()} | {:error, Changeset.t()}
  defdelegate insert(link_or_changeset), to: LinkEquipment.Repo

  def query(query), do: LinkEquipment.Repo.all(query)
end
