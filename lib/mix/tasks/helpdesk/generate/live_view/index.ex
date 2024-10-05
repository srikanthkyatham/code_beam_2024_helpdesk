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
    ash_table_component = table_component_name(igniter)

    # module plural name
    module_plural_name = get_plural_module_name(module)
    id = "#{module_plural_name}_id"
    resource_live_path = module_plural_name

    code =
      """
        <div>
          <.live_component
            id="#{id}"
            limit={10}
            offset={0}
            sort={{"id", :asc}}
            read_options={[{:tenant, @current_tenant}]}
            module={#{ash_table_component}}
            resource={#{module}}
            resource_live_path={"#{resource_live_path}"}
            query={#{module}}
            api={#{domain}}
            resource_id={@resource_id}
            live_action={@live_action}
            tenant={@current_tenant}
            url={@url}
          />
      </div>
      """

    path = get_module_heex_file_path(igniter, module, "index.html.heex")
    Igniter.create_new_file(igniter, path, code)
  end

  def add_index_ex(igniter, domain, module) do
    web_module = web_module(igniter)
    module_plural_name = get_plural_module_name(module)
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

    code =
      """
      use #{web_module}, :live_view
      alias #{module}

      @limit 10
      @offset 10

      require Ash.Sort
      require Logger

      @impl true
      def mount(params, _session, socket) do
        org_slug = params["org_slug"]
        current_tenant = Reservation.Orgs.get_org!(org_slug).id
        read_options = Keyword.put([], :page, limit: @limit, offset: @offset)

        {:ok,
        socket
        |> assign(index_params: nil)
        |> assign(:org_slug, org_slug)
        |> assign(:current_tenant, current_tenant)
        |> assign(:domain, #{domain})
        |> assign(:resource, #{module})
        |> assign(:read_options, read_options)}
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
        current_tenant = socket.assigns.current_tenant
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
        |> assign_#{module_plural_name}(params)
        |> assign(index_params: params)
      end

      defp current_index_path(index_params, current_tenant) do
        index_params = index_params || %{}
        EEx.eval_string("/app/org/<%= @current_tenant %>/#{module_plural_name}?<%= @index_params %>", assigns: [current_tenant: current_tenant, index_params: index_params])
      end

      defp assign_#{module_plural_name}(socket, params) do
        resource = socket.assigns.resource
        read_options = socket.assigns.read_options
        domain = socket.assigns.domain

        records = resource
                  |> domain.read!(read_options)

        assign(socket, records: records)
      end
      """

    index_module = get_module_name(igniter, module)

    create_module(igniter, index_module, code)
  end
end
