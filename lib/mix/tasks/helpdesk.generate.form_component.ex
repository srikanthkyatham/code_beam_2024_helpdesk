defmodule Mix.Tasks.Helpdesk.Generate.FormComponent do
  import Mix.Tasks.Helpdesk.Generate.Util
  require Logger

  def add_all_form_modules(igniter, modules) do
    igniter
    |> add_form_helper()
    # |> add_core_form_component()

    |> add_form_component_ext()
    |> add_form_components(modules)
  end

  defp add_form_components(igniter, modules) do
    form_component_ext = form_component_ext_name(igniter)
    # create file if does not exist
    {exists, igniter} = Igniter.Project.Module.module_exists?(igniter, form_component_ext)

    if exists do
      path = Igniter.Project.Module.proper_location(igniter, form_component_ext)

      Enum.reduce(modules, igniter, fn module, igniter ->
        Igniter.update_elixir_file(igniter, path, fn zipper ->
          for_every_module_add_form(igniter, zipper, module)
        end)
      end)
    else
      igniter
      |> add_form_component_ext()
      |> add_form_components(modules)
    end
  end

  defp for_every_module_add_form(igniter, zipper, module) do
    form_component = form_component_name(igniter)

    with {:ok, zipper} <- Igniter.Code.Common.move_to_do_block(zipper) do
      Logger.info("success in matching")
      # for
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
            <.inputs_for :let={nested_form} field={@form[@attribute.name]} id={@name}>
              <%= for nested_field <- @nested_fields do %>
                <%= #{form_component}.render_attribute_input(assigns, nested_field, nested_form, nil, nil) %>
              <% end %>
            </.inputs_for>
          </div>
        \"""
      end
      """

      # find every attribute and

      # how to move outside
      zipper
      |> Igniter.Code.Common.add_code(new_code, :after)
    else
      error ->
        Logger.info("error #{inspect(error)}")
        {:warning, "..."}
    end
  end

  defp add_form_helper(igniter) do
    webmodule = web_module(igniter)
    form_helper_module_name = (webmodule <> ".Ash.FormHelper") |> string_to_module_name()

    igniter
    |> Igniter.Code.Module.create_module(form_helper_module_name, """
    def fields_of_resource(resource) do
      resource
      |> Ash.Resource.Info.attributes()
      |> Enum.reject(fn attribute -> attribute.name in [:id, :inserted_at, :updated_at, :org_id] end)
    end

    def add_form_if_needed(form, attribute) do
      case form[attribute.name].form.data do
        nil -> AshPhoenix.Form.add_form(form, attribute.name)
        _ -> form
      end
    end

    def patch_path(url) do
      uri = URI.parse(url)
      uri_path = uri.path

      result = String.split(uri_path, "/new")

      case result do
        [_base] ->
          result = String.split(uri_path, "/edit")

          case result do
            [base] -> base
            [base, query] -> base <> query
          end

        [base, query] ->
          base <> query
      end
    end
    """)
  end

  def add_form_component_ext(igniter) do
    webmodule = web_module(igniter)
    form_component_ext = form_component_ext_name(igniter)

    igniter
    |> Igniter.Code.Module.create_module(
      form_component_ext,
      """
      use Phoenix.LiveComponent

      use Phoenix.VerifiedRoutes,
      endpoint: #{webmodule}.Endpoint,
      router: #{webmodule}.Router,
      statics: #{webmodule}.static_paths()

      import #{webmodule}.CoreComponents
      import #{webmodule}.Ash.FormHelper

      """
    )
  end

  defp form_component_ext_name(igniter) do
    webmodule = web_module(igniter)
    (webmodule <> ".Ash.FormComponentExt") |> string_to_module_name()
  end

  defp form_component_name(igniter) do
    web_module = web_module(igniter)
    Igniter.Code.Module.parse("#{web_module}.Ash.FormComponent")
  end

  defp add_core_form_component(igniter) do
    web_module = web_module(igniter)

    template_path = Path.expand("templates/form_component.eex")

    form_module_name =
      form_component_name(igniter)

    assigns =
      Keyword.merge(
        Map.to_list(igniter.assigns),
        module_name: form_module_name,
        web_module: web_module
      )

    Igniter.copy_template(
      igniter,
      template_path,
      Igniter.Project.Module.proper_location(igniter, form_module_name),
      assigns
    )
  end
end
