defmodule Mix.Tasks.Helpdesk.Generate.LiveView.Index do
  import Mix.Tasks.Helpdesk.Generate.Util
  import Mix.Tasks.Helpdesk.Generate.LiveView.Util

  def add_index_files(igniter, domain, module) do
    igniter
    |> add_index_ex(domain, module)
    |> add_index_html_heex(domain, module)
  end

  def add_index_html_heex(igniter, domain, module) do
    # inject live specific stuff
    # create the path
    # add modules with the code for the respective
    # more deduction
    # create index, show, form
    ash_table_component = table_component_name()

    # module plural name
    module_plural_name = get_plural_module_name(module)
    id = "#{module_plural_name}_id"
    path = module_plural_name

    code_start =
      """
      <div>
        <.live_component
          id="#{id}"
          module={#{ash_table_component}}
          limit={10}
          offset={0}
          sort={{"id", :asc}}
          query={#{module}}
          read_options={[{:tenant, @current_tenant}]}
          path={"#{path}"}
          api={#{domain}}
          resource_id={@resource_id}
          live_action={@live_action}
          tenant={@current_tenant}
          url={@url}
        >

      """

    attributes = resource_attributes(module) |> prune_attributes()

    # remove attributes which are relationship, or embedded or array

    code_middle = """
    """

    code_middle =
      Enum.reduce(attributes, code_middle, fn attribute, acc ->
        # generate
        name = attribute.name |> Atom.to_string()
        label = name |> String.capitalize()

        col_row = """
           <:col :let={record} label="#{label}"><%= record.#{name} %></:col>
        """

        acc <> col_row
      end)

    # button
    # modal

    form_component_name = form_component_name(igniter)

    base_path = scope_path() <> "/" <> "#" <> "{" <> "@org_slug}/" <> module_plural_name
    inferred_path = "#" <> "{" <> "@path}"

    code_end = """
    </.live_component>

    <div class="flex px-3 py-2 bg-gray-100 gap-2">
      <.button
        phx-click={JS.patch("#{base_path}/new")}
        type="button"
        class="rounded bg-white px-3 py-1 text-sm font-semibold text-gray-700 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
      >
        <.icon name="hero-plus" class="h-4 -mt-1" />Create
      </.button>
    </div>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="modal"
      show
      on_cancel={JS.patch("#{inferred_path}")}
    >
      <.live_component
        module={#{form_component_name}}
        resource={#{module}}
        live_action={@live_action}
        record={@record}
        api={#{domain}}
        id="#{id}"
        name="#{module_plural_name}_form"
        path={"#{path}"}
        tenant={@current_tenant}
      />
    </.modal>
    </div>
    """

    new_code = code_start <> code_middle <> code_end

    path = get_module_heex_file_path(igniter, module, "index.html.heex")
    Igniter.create_new_file(igniter, path, new_code)
  end

  def add_index_ex(igniter, domain, module) do
    web_module = web_module(igniter)
    # api -> domain
    # api.get
    # api.read
    # sort options
    # api.delete
    title =
      split_module_name(module)
      |> Enum.map(fn str -> String.downcase(str) end)
      |> Enum.join(" ")
      |> String.capitalize()

    # how to get the org
    # current tenant ??

    module_plural_name = get_plural_module_name(module)

    code =
      """
      use #{web_module}, :live_view

      @limit 10
      @offset 10

      require Ash.Sort
      require Logger

      @impl true
      def mount(params, _session, socket) do
        org_slug = params["org_slug"]
        {:ok, org} = Helpdesk.Orgs.org_by_slug(org_slug)
        current_tenant = org.id

        read_options = Keyword.put([], :page, limit: @limit, offset: @offset)

        {:ok,
        socket
        |> assign(index_params: nil)
        |> assign(:org_slug, org_slug)
        |> assign(:current_tenant, current_tenant)
        |> assign(:domain, #{domain})
        |> assign(:resource, #{module})
        |> assign(:read_options, read_options)
        |> assign(:path, "#{module_plural_name}")
        }
      end

      @impl true
      def handle_params(params, url, socket) do

        {:noreply,
          socket
          |> apply_action(socket.assigns.live_action, params)
          |> assign(:resource_id, params["id"])
          |> assign(:url, url)
          }
      end

      defp apply_action(socket, :edit, %{"id" => id}) do
        #current_tenant = socket.assigns.current_tenant
        domain = socket.assigns.domain
        read_options = socket.assigns.read_options
        resource = socket.assigns.resource

        record =
        domain.get!(resource, id, read_options)

        socket
        |> assign(:page_title, "Edit #{title}")
        |> assign(:record, record)
      end

      defp apply_action(socket, :new, _params) do
        socket
        |> assign(:page_title, "New #{title}")
        |> assign(:record, %#{module}{})
      end

      defp apply_action(socket, :index, params) do
        socket
        |> assign(:page_title, "Listing #{title}s")
        |> assign(index_params: params)
      end

      """

    index_module = get_module_name(igniter, module)

    create_module(igniter, index_module, code)
  end

  defp base_type?({:array, _resource} = _attribute) do
    false
  end

  defp base_type?(_resource) do
    true
  end

  # TODO: fix this
  defp prune_attributes(attributes) do
    Enum.reject(attributes, fn attribute ->
      Ash.Type.embedded_type?(attribute.type) || !base_type?(attribute)
    end)
  end
end
