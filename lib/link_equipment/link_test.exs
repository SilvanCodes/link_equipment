defmodule LinkEquipment.LinkTest do
  use LinkEquipment.DataCase

  alias LinkEquipment.Link

  test "all_from_source/1" do
    wanted_source = URI.parse(Faker.Internet.url())
    other_source = URI.parse(Faker.Internet.url())

    {:ok, _} = insert(Link, %{source_document_url: wanted_source})
    {:ok, _} = insert(Link, %{source_document_url: wanted_source})

    insert(Link, %{source_document_url: other_source})

    assert [%{source_document_url: ^wanted_source}, %{source_document_url: ^wanted_source}] =
             wanted_source |> Link.all_from_source() |> Link.Repo.query()
  end
end
