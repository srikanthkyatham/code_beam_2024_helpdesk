defmodule Mix.Tasks.Helpdesk.Generate.Util do
  def app_name(igniter) do
    {app_name, _} = Igniter.Project.Application.app_module(igniter)

    [elixir, app_name_module, _] =
      app_name
      |> Atom.to_string()
      |> String.split(".")

    Module.safe_concat([elixir, app_name_module]) |> Atom.to_string()
  end

  def web_module(igniter) do
    Igniter.Libs.Phoenix.web_module(igniter) |> Atom.to_string()
  end

  def table_component_name(igniter) do
    webmodule = web_module(igniter)

    (webmodule <> ".Ash.Table") |> string_to_module_name()
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

  def get_module_base_name(module) do
    Module.split(module) |> List.last()
  end

  def split_module_name(module) do
    actual_name = get_module_base_name(module)

    Regex.split(~r/(?=[A-Z])/, actual_name)
    |> Enum.reject(fn str -> str == "" end)
  end

  def module_name_to_string_with_underscores(module_name) do
    split_module_name(module_name)
    |> Enum.map(fn str -> String.downcase(str) end)
    |> Enum.join("_")
  end
end
