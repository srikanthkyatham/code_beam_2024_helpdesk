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

  def table_component_name() do
    "AshTable.Table" |> string_to_module_name()
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

  def resource_attributes(resource) do
    Ash.Resource.Info.attributes(resource)
  end

  def form_component_ext_name(igniter) do
    webmodule = web_module(igniter)
    (webmodule <> ".Ash.FormComponentExt") |> string_to_module_name()
  end

  def form_component_name(igniter) do
    web_module = web_module(igniter)
    Igniter.Code.Module.parse("#{web_module}.Ash.FormComponent")
  end

  def all_enum_resources(resources) do
    enum_resources = get_enum_resources(resources)
    # find attributes of resource

    attribute_enum_resources =
      Enum.reduce(resources, [], fn resource, acc ->
        get_attributes_enum(resource, acc)
      end)

    Enum.concat(enum_resources, attribute_enum_resources) |> Enum.uniq()
  end

  defp get_attributes_enum(resource, acc) do
    attributes = resource_attributes(resource)
    # remove all builtin attributes
    Enum.reduce(attributes, acc, fn attribute, acc ->
      enum_resource?(attribute, acc)
    end)
  end

  defp base_type_enum?({:array, resource} = _attribute, acc) do
    base_type_enum?(resource, acc)
  end

  defp base_type_enum?(resource, acc) do
    cond do
      Ash.Type.embedded_type?(resource) ->
        # get its attributes
        get_attributes_enum(resource, acc)

      !Ash.Type.builtin?(resource) and function_exported?(resource, :values, 0) ->
        [resource | acc]

      true ->
        acc
    end
  end

  defp enum_resource?(%Ash.Resource.Attribute{} = resource, acc) when is_list(acc) do
    base_type_enum?(resource.type, acc)
  end

  defp enum_resource?(resource, acc) when is_list(acc) do
    if function_exported?(resource, :values, 0) do
      [resource | acc]
    else
      acc
    end
  end

  defp get_enum_resources(resources) do
    Enum.reduce(resources, [], fn resource, acc ->
      enum_resource?(resource, acc)
    end)
  end
end
