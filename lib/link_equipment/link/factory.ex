defmodule LinkEquipment.Link.Factory do
  @moduledoc false
  use LinkEquipment.Factory

  alias LinkEquipment.Link

  @type fields :: %{
          optional(:url) => URI.t() | String.t(),
          optional(:source_document_url) => URI.t() | String.t(),
          optional(:html_element) => String.t() | nil,
          optional(:element_attribute) => String.t() | nil
        }

  @type opts :: [html_element: :a_tag | :audio_tag]

  @spec build(fields(), opts()) :: Link.t()
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

  defp html_element(fields, nil), do: fields

  defp html_element(fields, :a_tag),
    do: fields |> Map.put_new(:html_element, "a") |> Map.put_new(:element_attribute, "href")

  defp html_element(fields, :audio_tag),
    do: fields |> Map.put_new(:html_element, "audio") |> Map.put_new(:element_attribute, "src")
end
