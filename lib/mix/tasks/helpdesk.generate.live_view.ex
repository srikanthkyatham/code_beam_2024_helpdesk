defmodule Mix.Tasks.Helpdesk.Generate.LiveView do
  import Mix.Tasks.Helpdesk.Generate.Util

  def add_ash_table_component(igniter) do
    webmodule = web_module(igniter)
    table_component_module = (webmodule <> ".Ash.Table") |> string_to_module_name()
  end

  def add_live_view(igniter, domain, module) do
    # inject live specific stuff
    # create the path
    # add modules with the code for the respective
    # more deduction
    # create index, show, form
    ash_table_component = table_component_name(igniter)
    # module plural name
    module_plural_name = ""
    id = "#{module_plural_name}_id"
    resource_live_path = module_plural_name

    igniter
    |> Igniter.Code.Module.create_module(module, """
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
    """)
  end

  defp add_live_views(igniter, domain, modules) when is_list(modules) do
    ash_table_component = table_component_name(igniter)

    Enum.reduce(modules, igniter, fn module, igniter ->
      add_live_view(igniter, domain, module)
    end)
  end

  def add_live_views_to_router(igniter, modules) do
  end

  defp add_index_files(igniter, module) do
  end

  defp add_show_files(igniter, module) do
  end

  defp add_form_files(igniter, module) do
  end
end
