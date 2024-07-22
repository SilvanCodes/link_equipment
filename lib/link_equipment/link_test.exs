defmodule LinkEquipment.LinkTest do
  use LinkEquipment.DataCase

  alias LinkEquipment.Link

  test "all_from_source/1" do
    wanted_source = URI.parse(Faker.Internet.url())
    other_source = URI.parse(Faker.Internet.url())

    {:ok, _} = Link.Factory.insert(%{source_document_url: wanted_source})
    {:ok, _} = Link.Factory.insert(%{source_document_url: wanted_source})

    Link.Factory.insert(%{source_document_url: other_source})

    assert [_, _] = wanted_source |> Link.all_from_source() |> Link.Repo.query()
  end
end
