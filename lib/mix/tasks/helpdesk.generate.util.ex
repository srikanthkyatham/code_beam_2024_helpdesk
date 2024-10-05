defmodule Mix.Tasks.Helpdesk.Generate.Util do
  def web_module(igniter) do
    Igniter.Libs.Phoenix.web_module(igniter) |> Atom.to_string()
  end

  def table_component_name(igniter) do
    webmodule = web_module(igniter)

    (webmodule <> ".Components.AshTableComponent") |> string_to_module_name()
  end

  def string_to_module_name(module_name) do
    try do
      String.to_existing_atom(module_name)
    rescue
      _ ->
        String.to_atom(module_name)
    end
  end

  def create_module(igniter, module_name, code) do
    igniter
    |> Igniter.Code.Module.create_module(
      module_name,
      code
    )
  end
end
