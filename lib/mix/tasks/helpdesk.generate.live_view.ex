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
      Mix.Tasks.Helpdesk.Generate.LiveView.Index.add_index_files(igniter, domain, module)
    end)
  end

  def add_live_views_to_router(igniter, modules) do
  end
end
