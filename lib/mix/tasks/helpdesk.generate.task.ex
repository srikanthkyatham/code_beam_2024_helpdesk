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
  require Igniter.Code.Common

  require Logger

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
  #          - relationship table
  #          - aggregates table
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

    igniter
    # |> add_prepare_params_to_enum(all_enum_resources)
    |> add_form_components(resources)
  end

  # do this if the module is enum
  # or if the attribute of the resource is enum
  # defp add_prepare_params_to_enum(igniter, modules) when is_list(modules) do

  def do_add_prepare_params_to_enum(igniter, module) do
    path = Igniter.Project.Module.proper_location(igniter, module)

    Igniter.update_elixir_file(igniter, path, fn zipper ->
      with {:ok, zipper} <- Igniter.Code.Module.move_to_defmodule(zipper, module),
           {:ok, zipper} <- Igniter.Code.Common.move_to_do_block(zipper) do
        # some macro stuff is needed

        values =
          Enum.map(module.values(), fn value ->
            str = Atom.to_string(value)
            {String.capitalize(str), str}
          end)

        dbg()

        # only options is not working the other is working

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

  defp for_every_mod_add_form1(zipper, module) do
    # pattern = """
    # def render_attribute_input(assigns, attribute, form, value, _name)
    # """
    # move_to_def - moves zipper to the do block
    # need to
    # all same arity fns needs to be aligned the generic one being at the last
    # add_code after render_attribute_input/4
    # add_code before render_attributes/5
    # with {:ok, zipper} <- Igniter.Code.Function.move_to_def(zipper, :render_attribute_input, 5) do
    with {:ok, zipper} <- Igniter.Code.Common.move_to_do_block(zipper) do
      Logger.info("success in matching")

      new_code = """
      def render_attribute_input(
        assigns,
        %{type: #{module}} = attribute,
        form,
        value,
        name
      ) do
        nested_fields = fields_of_resource(attribute.type)

        updated_form =
          add_form_if_needed(form, attribute)

        assigns =
          assign(assigns,
            form: updated_form,
            value: value,
            name: name,
            attribute: attribute,
            nested_fields: nested_fields
          )

        ~H\"""
          <div>
            <.inputs_for :let={address_form} field={@form[@attribute.name]} id="address">
              <.input type="text" field={address_form[:city]} />
            </.inputs_for>
          </div>
        \"""
      end
      """

      # how to move outside
      zipper
      |> Igniter.Code.Common.add_code(new_code, :after)
    else
      error ->
        Logger.info("error #{inspect(error)}")
        {:warning, "..."}
    end
  end

  defp add_form_components(igniter, modules) do
    ash_form_component = HelpdeskWeb.Components.Ash.FormComponentExt
    path = Igniter.Project.Module.proper_location(igniter, ash_form_component)

    Enum.reduce(modules, igniter, fn module, igniter ->
      Igniter.update_elixir_file(igniter, path, fn zipper ->
        # group all changes of all modules
        # Enum.reduce(modules, zipper, fn module, zipper ->
        for_every_mod_add_form1(zipper, module)

        # end)
      end)
    end)
  end

  defp add_live_view(igniter, module) do
    # inject live specific stuff
    # create the path
    # add modules with the code for the respective
  end

  defp add_live_views(igniter, modules) when is_list(modules) do
    ash_table_component = HelpdeskWeb.Components.AshTableComponent

    Enum.reduce(modules, igniter, fn module, igniter ->
      add_live_view(igniter, module)
    end)
  end

  def add_to_router(igniter, modules) do
  end
end