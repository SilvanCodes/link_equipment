defmodule LinkEquipmentWeb.LivingSourceComponent do
  @moduledoc false
  use LinkEquipmentWeb, :html

  def render(assigns) do
    ~H"""
    <.async :let={source} :if={@source} assign={@source}>
      <:loading>
        <p>Getting source...</p>
      </:loading>
      <div id="living_source" phx-hook="LivingSource">
        <pre>
        <code id="basic_source">
    <%= source %>
        </code>
      </pre>
      </div>
      <:failed :let={_failure}>
        <p>There was an error getting the source. :(</p>
      </:failed>
    </.async>
    """
  end
end
