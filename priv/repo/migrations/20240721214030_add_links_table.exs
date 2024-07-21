defmodule LinkEquipment.Repo.Migrations.AddLinksTable do
  use Ecto.Migration

  def change do
    create table(:links) do
      add :url, :map, null: false
      add :source_document_url, :map, null: false
      add :html_element, :string, null: true
      add :element_attribute, :string, null: true

      timestamps()
    end
  end
end
