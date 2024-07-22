defmodule LinkEquipment.Link.Factory do
  @moduledoc false
  alias Ecto.Changeset
  alias LinkEquipment.Link

  @type opts :: [html_element: :a_tag | :audio_tag]

  @spec build(map(), opts()) :: Link.t()
  def build(fields \\ %{}, opts \\ [html_element: :a_tag]) do
    fields =
      fields
      |> Map.put_new(:url, Faker.Internet.url())
      |> Map.update!(:url, &URI.parse/1)
      |> Map.put_new(:source_document_url, Faker.Internet.url())
      |> Map.update!(:source_document_url, &URI.parse/1)
      |> html_element(opts[:html_element])

    struct(Link, fields)
  end

  @spec insert(map(), opts()) :: {:ok, Link.t()} | {:error, Changeset.t()}
  def insert(fields \\ %{}, opts \\ []), do: Link.Repo.insert(build(fields, opts))

  defp html_element(fields, nil), do: fields

  defp html_element(fields, :a_tag),
    do: fields |> Map.put_new(:html_element, "a") |> Map.put_new(:element_attribute, "href")

  defp html_element(fields, :audio_tag),
    do: fields |> Map.put_new(:html_element, "audio") |> Map.put_new(:element_attribute, "src")
end
