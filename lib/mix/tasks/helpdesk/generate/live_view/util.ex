defmodule Mix.Tasks.Helpdesk.Generate.LiveView.Util do
  import Mix.Tasks.Helpdesk.Generate.Util

  def get_module_name(igniter, module) do
    web_module = web_module(igniter)
    base_module_name = get_module_base_name(module)
    Igniter.Code.Module.parse("#{web_module}.Live.#{base_module_name}Live.Index")
  end

  def get_module_heex_file_path(igniter, module, file_name) do
    module_name = get_module_name(igniter, module)
    dbg()
    path = Igniter.Project.Module.proper_location(igniter, module_name)
    dirname = Path.dirname(path)
    Path.join([dirname, file_name])
  end

  def get_plural_module_name(module) do
    base_module_name = get_module_base_name(module)
    (base_module_name <> "s") |> String.downcase()
  end
end
