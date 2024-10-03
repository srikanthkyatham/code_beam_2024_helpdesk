defmodule Mix.Tasks.Helpdesk.Generate.Task do
  use Igniter.Mix.Task

  @example "mix helpdesk.generate.task Elixir.Helpdesk.Support"

  @shortdoc "Generates scaffold for liveview from domain resource definitions"
  @moduledoc """
  #{@shortdoc}

  Scaffolding for the liveview form domain

  ## Example

  ```bash
  #{@example}
  ```

  ## Options

  * [domain] - Module name of the domain
  """

  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      example: @example,
      positional: [{:domain, optional: true}]
    }
  end

  def igniter(igniter, argv) do
    {arguments, _argv} = positional_args!(argv)
    domain = domain(Map.get(arguments, :domain))
    resources = get_resources(domain)

    igniter
    |> Igniter.assign(domain: domain)
    |> prepare_enum_resources(resources)

    # |> add_form_components(resources)
    # |> add_live_views(resources)

    # igniter
    # |> Igniter.add_warning("mix helpdesk.generate.task is not yet implemented")
  end

  # issue with what are the embedded resources
  # iterate and find out
  # hard or can we fetch from the domain
  # generate live_view - based on
  #          - table
  #                 - relationship table
  #                 -
  # test module - copy the test setup - last
  #             - Ash.Generator
  # get the eex

  defp domain(domain) when is_binary(domain) do
    String.to_existing_atom(domain)
  end

  # collect the enum resources
  # resource could be embedded in itself

  defp base_type_enum?({:array, resource} = _attribute, acc) do
    dbg()
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
    dbg()
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

  defp get_resources(domain) when is_atom(domain) do
    Ash.Domain.Info.resource_references(domain) |> Enum.map(fn ref -> ref.resource end)
  end

  defp get_attributes_enum(resource, acc) do
    attributes = Ash.Resource.Info.attributes(resource)
    # remove all builtin attributes
    Enum.reduce(attributes, acc, fn attribute, acc ->
      enum_resource?(attribute, acc)
    end)
  end

  defp prepare_enum_resources(igniter, resources) do
    enum_resources = get_enum_resources(resources)
    # find attributes of resource

    attribute_enum_resources =
      Enum.reduce(resources, [], fn resource, acc ->
        get_attributes_enum(resource, acc)
      end)

    all_enum_resources = Enum.concat(enum_resources, attribute_enum_resources)

    dbg()

    igniter
    |> add_prepare_params_to_enum(all_enum_resources)
  end

  # do this if the module is enum
  # or if the attribute of the resource is enum
  defp add_prepare_params_to_enum(igniter, modules) when is_list(modules) do
    Enum.reduce(modules, igniter, fn module, igniter ->
      # atoms = module.values()

      # find module
      igniter
      |> Igniter.Code.Module.find_and_update_module(module, fn zipper ->
        # move zipper to respective place
        new_code = """
        IO.inspect("New code from zipper update")
        """

        pattern =
          """
          attributes do
             __
          end
          ____cursor__()
          """

        {:ok, zipper} =
          zipper
          |> Igniter.Code.Common.move_to_cursor(pattern)

        updated_zipper =
          zipper
          |> Igniter.Code.Common.add_code(new_code, :after)

        # add code
        {:ok, updated_zipper}
      end)
    end)
  end

  defp add_form_components(igniter, modules) when is_list(modules) do
    ash_form_component = HelpdeskWeb.Components.AshFormComponent

    Enum.reduce(modules, igniter, fn module, igniter ->
      igniter
      |> Igniter.Code.Module.find_and_update_module(ash_form_component, fn zipper ->
        # get the module and create the entry
        # move zipper to respective place
        # add code
        {:ok, igniter}
      end)
    end)
  end

  defp add_live_views(igniter, resources) when is_list(resources) do
    ash_table_component = HelpdeskWeb.Components.AshTableComponent

    Enum.reduce(resources, igniter, fn resource, igniter ->
      igniter
      |> Igniter.Code.Module.find_and_update_module(ash_table_component, fn zipper ->
        # get the module and create the entry
        # move zipper to respective place
        # add code
        {:ok, igniter}
      end)
    end)
  end
end
