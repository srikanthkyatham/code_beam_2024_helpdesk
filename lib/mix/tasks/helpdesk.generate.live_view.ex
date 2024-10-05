defmodule Mix.Tasks.Helpdesk.Generate.LiveView do
  import Mix.Tasks.Helpdesk.Generate.Util

  def add_live_views(igniter, domain, modules) when is_list(modules) do
    # live views
    # inject the proper things - refine
    # show
    # index
    # form
    modules = [List.first(modules)]

    Enum.reduce(modules, igniter, fn module, igniter ->
      add_live_view(igniter, domain, module)
    end)
  end

  defp add_live_view(igniter, domain, module) do
    # inject live specific stuff
    # create the path
    # add modules with the code for the respective
    # more deduction
    # create index, show, form
    web_module = web_module(igniter)
    ash_table_component = table_component_name(igniter)

    Igniter.Code.Module.parse("#{web_module}.live.#{module}live.Index")

    # module plural name
    module_plural_name = ""
    id = "#{module_plural_name}_id"
    resource_live_path = module_plural_name

    code =
      """
        <.container class="py-16">
        <.live_component
          id="#{id}"
          limit={10}
          offset={0}
          sort={{"id", :asc}}
          read_options={[{:tenant, @current_tenant}]}
          module={#{ash_table_component}}
          resource={#{module}}
          resource_live_path={#{resource_live_path}}
          query={#{module}}
          api={#{domain}}
          resource_id={@resource_id}
          live_action={@live_action}
          tenant={@current_tenant}
          url={@url}
        />
      </.container>
      """

    path = get_module_heex_file_path(igniter, module, "index.html.heex")
    Igniter.create_new_file(igniter, path, code)
  end

  def add_live_views_to_router(igniter, modules) do
  end

  defp add_index_files(igniter, module) do
  end

  defp add_index_html_heex_file(igniter, module) do
  end

  defp add_index_ex_file(igniter, module) do
  end

  defp add_show_files(igniter, module) do
  end

  defp add_form_files(igniter, module) do
  end

  defp get_module_name(igniter, module) do
    web_module = web_module(igniter)
    module_name = Module.split(module) |> List.last()
    # Module.safe_concat([web_module, Live, module, Index])
    Igniter.Code.Module.parse("#{web_module}.Live.#{module_name}Live.Index")
  end

  defp get_module_heex_file_path(igniter, module, file_name) do
    module_name = get_module_name(igniter, module)
    dbg()
    path = Igniter.Project.Module.proper_location(igniter, module_name)
    dirname = Path.dirname(path)
    Path.join([dirname, file_name])
  end
end
