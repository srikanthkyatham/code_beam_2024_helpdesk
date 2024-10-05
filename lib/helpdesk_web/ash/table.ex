defmodule HelpdeskWeb.Ash.Table do
  @moduledoc false
  use Phoenix.LiveComponent

  use Phoenix.VerifiedRoutes,
    endpoint: HelpdeskWeb.Endpoint,
    router: HelpdeskWeb.Router,
    statics: HelpdeskWeb.static_paths()

  alias Phoenix.LiveView.JS
  # import HelpdeskWeb.CoreComponents
  alias HelpdeskWeb.RowComponent

  require Ash.Query

  attr(:path, :string, required: true)
  attr(:name, :string, required: true)
  attr(:icon, :string, required: true)
  attr(:phxclick, :any, required: true)
  attr(:disabled, :boolean, required: true)
  # <wbutton path={"#{@resource_live_path}/new"} name="Create" icon="hero-plus" disabled={false}/>
  # <wbutton path={"#{@resource_live_path}/#{@selected_rows |> hd |> elem(0)}/edit"} name="Create" icon="hero-pencil" disabled={not @can_edit?} />
  # <wbutton path={"#{@resource_live_path}/#{@selected_rows |> hd |> elem(0)}/edit"} name="Create" icon="hero-pencil" disabled={not @can_edit?} />

  def wbutton(assigns) do
    ~H"""
    <button
      phx-click={@phxclick}
      type="button"
      class="rounded bg-white px-3 py-1 text-sm font-semibold text-gray-700 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
    >
      <icon name={@icon} class="h-4 -mt-1" />{@name}
    </button>
    """
  end

  attr(:resource, :atom)
  attr(:resource_live_path, :string)
  attr(:record, :any)

  def render(assigns) do
    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="w-[40rem] mt-11 sm:w-full">
        <thead class="text-sm text-left leading-6 text-zinc-500">
          <tr>
            <th
              :for={{col, i} <- @cols |> Enum.with_index()}
              phx-click="sort"
              phx-value-index={i}
              phx-target={@myself}
              style={"width: #{col.width}px"}
              data={[index: i]}
            >
              <%= col.title %>
              <.sort_icon col={col} />
            </th>
          </tr>
        </thead>
        <tbody class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700">
          <%= if @records == [] do %>
            <tr class="group hover:bg-zinc-50">
              <td colspan={length(@cols)}>
                <%= if @if_empty, do: render_slot(@if_empty), else: "No results" %>
              </td>
            </tr>
          <% end %>
          <.live_component
            :for={record <- @records}
            module={RowComponent}
            id={"row-#{record.id}"}
            record={record}
            cols={@cols}
            editing_cell={@editing_cell}
            phx-click="start_edit_cell"
            phx-value-row_id={record.id}
            parent={@myself}
          />
        </tbody>
      </table>

      <modal
        :if={@live_action in [:new, :edit]}
        id="modal"
        show
        on_cancel={JS.patch("#{@resource_live_path}")}
      >
        <.live_component
          module={HelpdeskWeb.PetalAshFormComponent}
          resource={@resource}
          live_action={@live_action}
          record={@record}
          api={@api}
          id="form"
          name="book"
          tenant={@tenant}
          resource_live_path={@resource_live_path}
          url={@url}
        />
      </modal>
    </div>
    """
  end

  def update(%{select_row: row}, socket) do
    selected_rows = [row | socket.assigns.selected_rows]

    {:ok,
     socket
     |> assign(:selected_rows, selected_rows)
     |> assign(:can_edit?, length(selected_rows) == 1)
     |> assign(:can_delete?, length(selected_rows) > 0)}
  end

  def update(%{unselect_row: record_id}, socket) do
    selected_rows = Enum.reject(socket.assigns.selected_rows, fn {id, _} -> id == record_id end)

    {:ok,
     socket
     |> assign(:selected_rows, selected_rows)
     |> assign(:can_edit?, length(selected_rows) == 1)
     |> assign(:can_delete?, length(selected_rows) > 0)}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:selected_rows, fn -> [] end)
      |> assign_new(:can_edit?, fn -> false end)
      |> assign_new(:can_delete?, fn -> false end)

    resource = socket.assigns.resource

    api = socket.assigns.api
    # limit = socket.assigns.limit
    # offset = socket.assigns.offset

    # TODO issue is here - which of the resource_id should be given if none exists
    # there should be if condition
    # inject read options to the api.get!

    # all_read_options = Keyword.put(read_options, :page, limit: limit, offset: offset)
    read_options = socket.assigns.read_options
    all_read_options = read_options

    record =
      socket.assigns.resource_id &&
        api.get!(resource, socket.assigns.resource_id, all_read_options)

    cols =
      resource
      |> Ash.Resource.Info.fields([:attributes])
      |> Enum.reject(fn attribute ->
        attribute.name in [:id] || Ash.Type.embedded_type?(attribute.type)
      end)
      |> Enum.map(fn attribute ->
        %{
          name: attribute.name,
          title: attribute.name |> to_string() |> String.upcase() |> String.replace("_", " "),
          width: default_width(attribute.type),
          sort: if(attribute.name == :inserted_at, do: :asc),
          read_only: attribute.name in [:id, :inserted_at, :updated_at]
        }
      end)

    sort =
      cols
      |> Enum.find(fn col -> col[:sort] end)
      |> case do
        nil -> []
        %{name: name, sort: sort_order} -> {name, sort_order}
      end

    records =
      resource
      |> Ash.Query.sort(sort)
      |> api.read!(all_read_options)

    {:ok,
     assign(
       socket,
       Map.merge(assigns, %{
         resource: resource,
         api: api,
         records: records,
         cols: cols,
         record: record,
         editing_cell: %{
           field: nil,
           row_id: nil
         }
       })
     )}
  end

  def handle_event("show_add_modal", _params, socket) do
    {:noreply, assign(socket, show_add_modal: true)}
  end

  def handle_event("sort", %{"index" => index} = _params, socket) do
    index = String.to_integer(index)

    # Update the order of the columns in assigns
    cols = socket.assigns.cols
    read_options = socket.assigns.read_options

    cols =
      cols
      |> Enum.with_index()
      |> Enum.map(fn {col, i} ->
        if i == index do
          sort_order =
            case col[:sort] do
              nil -> :asc
              :asc -> :desc
              :desc -> nil
            end

          Map.put(col, :sort, sort_order)
        else
          Map.put(col, :sort, nil)
        end
      end)

    sort =
      cols
      |> Enum.find(fn col -> col[:sort] end)
      |> case do
        nil -> []
        %{name: name, sort: sort_order} -> {name, sort_order}
      end

    all_read_options = read_options

    records =
      socket.assigns.resource
      |> Ash.Query.sort(sort)
      |> socket.assigns.api.read!(all_read_options)

    {:noreply, assign(socket, cols: cols, records: records)}
  end

  def handle_event("reposition", %{"index" => index, "new" => new_index} = _params, socket) do
    # Somehow Sortable passes index as a string, as opposed to new_index
    index = String.to_integer(index)

    # Update the order of the columns in assigns
    cols = socket.assigns.cols

    cols =
      cols
      |> Enum.with_index()
      |> Enum.reject(fn {_, i} -> i == index end)
      |> Enum.map(fn {col, _i} -> col end)
      |> List.insert_at(new_index, Enum.at(cols, index))

    {:noreply, assign(socket, cols: cols)}
  end

  def handle_event("resize", %{"width" => width, "index" => index} = _params, socket) do
    # Update the width of the column in assigns
    cols = socket.assigns.cols

    cols =
      cols
      |> Enum.with_index()
      |> Enum.map(fn {col, i} ->
        if i == index do
          %{col | width: width}
        else
          col
        end
      end)

    {:noreply, assign(socket, cols: cols)}
  end

  def handle_event("delete", _params, socket) do
    ids =
      Enum.map(socket.assigns.selected_rows, fn {id, _} -> id end)

    read_options = socket.assigns.read_options

    all_options = Keyword.put(read_options, :domain, socket.assigns.api)

    socket.assigns.resource
    |> Ash.Query.filter(id in ^ids)
    |> socket.assigns.api.read!(all_options)
    |> Enum.each(fn record -> Ash.destroy!(record, all_options) end)

    # Update the width of the column in assigns
    {:noreply, assign(socket, selected_rows: [], can_edit?: false, can_delete?: false)}
  end

  defp sort_icon(assigns) do
    ~H"""
    <span :if={@col[:sort]} class="ml-2 flex-none rounded text-gray-900 group-hover:bg-gray-200">
      <icon :if={@col[:sort] == :asc} name="hero-arrow-up" class="h-3" />
      <icon :if={@col[:sort] == :desc} name="hero-arrow-down" class="h-3" />
    </span>
    """
  end

  defp default_width(Ash.Type.Integer), do: 100
  defp default_width(Ash.Type.Date), do: 150
  defp default_width(_), do: 300
end
