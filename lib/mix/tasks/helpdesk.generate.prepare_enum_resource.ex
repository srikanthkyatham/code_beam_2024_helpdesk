defmodule Mix.Tasks.Helpdesk.Generate.PrepareEnumResources do
  require Logger

  def prepare_enum_resources(igniter, resources) do
    enum_resources = get_enum_resources(resources)
    # find attributes of resource

    attribute_enum_resources =
      Enum.reduce(resources, [], fn resource, acc ->
        get_attributes_enum(resource, acc)
      end)

    all_enum_resources = Enum.concat(enum_resources, attribute_enum_resources)

    igniter
    |> add_prepare_params_to_enum(all_enum_resources)
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

  defp get_attributes_enum(resource, acc) do
    attributes = Ash.Resource.Info.attributes(resource)
    # remove all builtin attributes
    Enum.reduce(attributes, acc, fn attribute, acc ->
      enum_resource?(attribute, acc)
    end)
  end

  def do_add_prepare_params_to_enum(igniter, module) do
    path = Igniter.Project.Module.proper_location(igniter, module)

    Igniter.update_elixir_file(igniter, path, fn zipper ->
      with {:ok, zipper} <- Igniter.Code.Module.move_to_defmodule(zipper, module),
           {:ok, zipper} <- Igniter.Code.Common.move_to_do_block(zipper) do
        values =
          Enum.map(module.values(), fn value ->
            str = Atom.to_string(value)
            {String.capitalize(str), str}
          end)

        new_code = """
        alias Helpdesk.Utils.MethodToParam


        def options do
          #{inspect(values)}
        end

        def to_method(param) when is_binary(param) do
          String.to_existing_atom(param)
        end

        def to_method({_label, value} = param) when is_tuple(param) do
          to_method(value)
        end


        def to_method(method) when is_atom(method) do
          Atom.to_string(method)
        end

        def to_strings(methods) when is_list(methods) do
          MethodToParam.to_methods(methods, &#{module}.to_method/1)
        end

        def to_methods(params) do
          MethodToParam.to_methods(params, &#{module}.to_method/1)
        end
        """

        zipper
        |> Igniter.Code.Common.add_code(new_code, :after)
      else
        error ->
          Logger.info("error #{inspect(error)}")

          {:warning, "...."}
      end
    end)
  end

  def add_prepare_params_to_enum(igniter, modules) do
    Enum.reduce(modules, igniter, fn module, igniter ->
      do_add_prepare_params_to_enum(igniter, module)
    end)
  end
end
