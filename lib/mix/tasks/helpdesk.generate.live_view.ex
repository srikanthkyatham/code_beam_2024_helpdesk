defmodule Mix.Tasks.Helpdesk.Generate.LiveView do
  import Mix.Tasks.Helpdesk.Generate.Util

  def add_live_view_files_and_routes(igniter, domain, modules) when is_list(modules) do
    igniter
    |> add_live_views(domain, modules)
    |> add_live_views_to_router(modules)
  end

  defp add_live_views(igniter, domain, modules) when is_list(modules) do
    # live views
    # inject the proper things - refine
    # show
    # index
    # form
    # modules = [List.first(modules)]

    Enum.reduce(modules, igniter, fn module, igniter ->
      Mix.Tasks.Helpdesk.Generate.LiveView.Index.add_index_files(igniter, domain, module)
    end)
  end

  defp add_live_views_to_router(igniter, modules) do
    {igniter, routers} = Igniter.Libs.Phoenix.list_routers(igniter)
    router = List.first(routers)

    contents = get_routes(igniter, modules)

    options = [router: router]
    route = "/app/org"
    Igniter.Libs.Phoenix.append_to_scope(igniter, route, contents, options)
  end

  defp get_routes(igniter, modules) do
    contents = """

    """

    web_module = web_module(igniter)

    Enum.reduce(modules, contents, fn module, acc ->
      base_route = module_name_to_string_with_underscores(module) <> "s"
      base_module_name = get_module_base_name(module)
      base = Igniter.Code.Module.parse("#{web_module}.Live.#{base_module_name}Live")
      index_module = Igniter.Code.Module.parse("#{base}.Index")
      show_module = Igniter.Code.Module.parse("#{base}.Show")

      # live("/business_units", BusinessUnitLive.Index, :index)
      # live("/business_units/new", BusinessUnitLive.Index, :new)
      # live("/business_units/:id/edit", BusinessUnitLive.Index, :edit)

      # live("/business_units/:id", BusinessUnitLive.Show, :show)
      # live("/business_units/:id/show/edit", BusinessUnitLive.Show, :edit)

      routes =
        """
        live("/#{base_route}", #{index_module}, :index)
        live("/#{base_route}/new", #{index_module}, :new)
        live("/#{base_route}/:id/edit", #{index_module}, :edit)

        live("/#{base_route}/:id", #{show_module}, :show)
        live("/#{base_route}/:id/show/edit", #{show_module}, :edit)

        """

      acc <> routes
    end)
  end
end
