defmodule LinkEquipment.Link.RepoTest do
  use LinkEquipment.DataCase

  alias LinkEquipment.Link

  test "insert/1" do
    link = Link.Factory.build()

    assert {:ok, _} = Link.Repo.insert(link)
  end
end
