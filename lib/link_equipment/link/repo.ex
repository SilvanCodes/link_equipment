defmodule LinkEquipment.Link.Repo do
  alias Ecto.Changeset
  alias LinkEquipment.Link

  @spec insert(Link.t() | Changeset.t()) :: {:ok, Link.t()} | {:error, Changeset.t()}
  def insert(%Link{} = link) do
    LinkEquipment.Repo.insert(link)
  end

  def insert(%Changeset{} = changeset) do
    LinkEquipment.Repo.insert(changeset)
  end
end
