defmodule HelpdeskWeb.Ash.TableRow do
  @moduledoc false
  use Phoenix.LiveComponent
  alias Phoenix.LiveView.JS

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:selected, fn -> false end)
     |> assign_new(:editing_field, fn -> nil end)
     |> assign_new(:record, fn -> nil end)}
  end

  def handle_event("start_edit_cell", params, socket) do
    {:noreply, assign(socket, editing_field: params["field"])}
  end

  def handle_event("stop_edit", _params, socket) do
    {:noreply, assign(socket, editing_field: nil)}
  end

  def handle_event("select", _params, socket) do
    if socket.assigns.selected do
      send_update(
        socket.assigns.parent,
        unselect_row: socket.assigns.record.id
      )
    else
      send_update(
        socket.assigns.parent,
        select_row: {socket.assigns.record.id, socket.assigns.myself}
      )
    end

    {:noreply, assign(socket, selected: !socket.assigns.selected)}
  end

  # This only happens when editing_cell is set
  def handle_event("enter", %{"value" => value}, socket) do
    updated_record =
      socket.assigns.record
      |> Ash.Changeset.for_update(:update, %{
        socket.assigns.editing_field => value
      })
      |> Ash.update!()

    {:noreply, assign(socket, editing_field: nil, record: updated_record)}
  end

  def render(assigns) do
    ~H"""
    <tr
      data={[index: @record.id]}
      id={"tr-#{@record.id}"}
      phx-click="select"
      phx-target={@myself}
      phx-value-row_id={@record.id}
      class={["relative p-0"]}
    >
      <td
        :for={col <- @cols}
        phx-value-row_id={@record.id}
        phx-value-field={col.name}
        phx-target={@myself}
      >
        <div :if={!(@editing_field == col.name |> to_string)} class="py-1 px-3">
          <div
            data-dblclick={unless col.read_only, do: JS.push("start_edit_cell")}
            phx-value-row_id={@record.id}
            phx-value-field={col.name}
            phx-target={@myself}
          >
            <%= Map.get(@record, col.name) %>
          </div>
        </div>
      </td>
    </tr>
    """
  end
end
