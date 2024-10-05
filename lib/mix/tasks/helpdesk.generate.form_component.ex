defmodule Mix.Tasks.Helpdesk.Generate.FormComponent do
  import Mix.Tasks.Helpdesk.Generate.Util
  require Logger

  def add_all_form_modules(igniter, modules) do
    igniter
    |> add_form_helper()
    |> add_core_form_component()
    |> add_form_component_ext()
    |> add_form_components(modules)
  end

  defp add_form_components(igniter, modules) do
    form_component_ext = form_component_ext_name(igniter)
    # create file if does not exist
    {exists, igniter} = Igniter.Project.Module.module_exists?(igniter, form_component_ext)

    if exists do
      path = Igniter.Project.Module.proper_location(igniter, form_component_ext)

      igniter =
        Enum.reduce(modules, igniter, fn module, igniter ->
          Igniter.update_elixir_file(igniter, path, fn zipper ->
            for_every_module_add_form(igniter, zipper, module)
          end)
        end)

      # default renders for builts in
      Igniter.update_elixir_file(igniter, path, fn zipper ->
        add_render_for_array_of_builts(igniter, zipper)
      end)
    else
      igniter
      |> add_form_component_ext()
      |> add_form_components(modules)
    end
  end

  defp add_render_for_array_of_builts(igniter, zipper) do
    form_component = form_component_name(igniter)

    new_code = """
    def render_array_attribute_input(
      assigns,
      %{type: {:array, _builtin_type}} = attribute,
      form,
      value,
      name
    ) do
      updated_form =
        add_form_if_needed(form, attribute)

      assigns =
        assign(assigns,
          form: updated_form,
          value: value,
          name: name,
          attribute: attribute,
        )

        ~H\"""
          <div>
              <%= for attribute <- @attribute do %>
                <%= #{form_component}.render_attribute_input(assigns, attribute, @form, nil, nil) %>
              <% end %>
          </div>
        \"""
    end
    """

    add_code_to_zipper(zipper, new_code)
  end

  defp for_every_module_add_form(igniter, zipper, module) do
    form_component = form_component_name(igniter)

    new_code = """
    def render_attribute_input(
      assigns,
      %{type: {:array, #{module}}} = attribute,
      form,
      value,
      name
    ) do
      # could be composite or built_in
      if Ash.Type.builtin?(#{module}) do
        ~H\"""
          <%= render_array_attribute_input(assigns, attribute, @form, nil, nil) %>
        \"""

      else
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

    end

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

    add_code_to_zipper(zipper, new_code)
  end

  defp add_form_helper(igniter) do
    webmodule = web_module(igniter)
    form_helper_module_name = (webmodule <> ".Ash.FormHelper") |> string_to_module_name()

    create_module(igniter, form_helper_module_name, """
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

    create_module(igniter, form_component_ext, """
    use Phoenix.LiveComponent

    use Phoenix.VerifiedRoutes,
    endpoint: #{webmodule}.Endpoint,
    router: #{webmodule}.Router,
    statics: #{webmodule}.static_paths()

    import #{webmodule}.CoreComponents
    import #{webmodule}.Ash.FormHelper

    """)
  end

  defp form_component_ext_name(igniter) do
    webmodule = web_module(igniter)
    (webmodule <> ".Ash.FormComponentExt") |> string_to_module_name()
  end

  defp form_component_name(igniter) do
    web_module = web_module(igniter)
    Igniter.Code.Module.parse("#{web_module}.Ash.FormComponent")
  end

  # issues with compilation
  defp add_core_form_component(igniter) do
    web_module = web_module(igniter)

    module_name =
      form_component_name(igniter)

    base_module_name = get_module_base_name(module_name)
    plural_module_name = base_module_name <> "s"

    code = """
    use Phoenix.LiveComponent

    use Phoenix.VerifiedRoutes,
    endpoint: #{web_module}.Endpoint,
    router: #{web_module}.Router,
    statics: #{web_module}.static_paths()

    import #{web_module}.CoreComponents

    alias Ash.Resource.Info


    def update(assigns, socket) do
    resource = assigns.resource
    api = assigns.api

    fields =
      resource
      |> #{web_module}.Ash.FormHelper.fields_of_resource()

    prepare_params = collect_prepare_params(fields)

    if_result =
      if assigns.live_action == :new do
        AshPhoenix.Form.for_create(resource, :create, api: api, prepare_params: prepare_params)
      else
        AshPhoenix.Form.for_update(assigns.record, :update,
          api: api,
          prepare_params: prepare_params
        )
      end

    form =
      to_form(if_result)

    {:ok,
     assign(
       socket,
       Map.merge(assigns, %{
         resource: resource,
         api: api,
         fields: fields,
         form: form
       })
     )}
    end


    def handle_event("validate", %{"form" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form, params || %{})

    {:noreply, assign(socket, :form, form)}
    end

    def handle_event("save", _, socket) do
    form = socket.assigns.form

    case AshPhoenix.Form.submit(form,
           params: form.source.params,
           force?: true
         ) do
      {:ok, _result} ->
        {:noreply,
         socket
         |> put_flash(:info, "Flash")
         |> push_patch(to: "/ash/#{plural_module_name}")}

      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, "Flash")
         |> push_patch(to: "/ash/#{plural_module_name}")}

      {:error, form} ->
        {:noreply, assign(socket, :form, form)}
    end
    end

      def attribute_name(attribute) do
        attribute.name
      end
      def form_name(name, attribute) do
        name <> attribute.name
      end

      def form_id(id, attribute) do
        id <> attribute.name
      end
      def render_attributes(assigns, _resource, _action, _form) do
      ~H\"""
      <div :for={attribute <- @fields} class="col-span-1">
        <div phx-feedback-for={form_name(@form.name, attribute)}>
          <label
            class="block text-sm font-medium text-gray-700"
            for={@form.name <> "[attribute_name(attribute)]"}
          >
            <%= to_name(attribute.name) %>
          </label>
          <%= render_attribute_input(assigns, attribute, @form, nil, nil) %>
        </div>
      </div>
      \"""
      end

      def render_attribute_input(assigns, %{type: Ash.Type.Date} = attribute, form, value, name) do
      assigns = assign(assigns, form: form, value: value, name: name, attribute: attribute)

      ~H\"""
      <.input
        type="date"
        value={value(@value, @form, @attribute)}
        name={@name || [attribute_name(@attribute)]}
        id={form_id(@form.id, @attribute)}
      />
      \"""

      end

      def render_attribute_input(assigns, attribute, form, _value, _name) do
      assigns = assign(assigns, attribute: attribute, form: form)

      ~H\"""
      <.input
        type="text"
        field={@form[@attribute.name]}
        disabled={false && @attribute.read_only}
        class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
      />
      \"""
      end


      def render(assigns) do
      ~H\"""
      <div>
        <.header>New <%= Info.short_name(@resource) %></.header>
        <.form
          :let={form}
          as={:action}
          for={@form}
          phx-change="validate"
          phx-submit="save"
          phx-target={@myself}
          id={"#{@id}_form"}
        >
          <div class="my-4 grid grid-cols-1 md:grid-cols-2 gap-4">
            <%= render_attributes(assigns, @resource, nil, form) %>
          </div>
          <.button phx-disable-with="Saving...">Save</.button>
        </.form>
      </div>
      \"""
      end



    defp value(value, form, attribute, default \\\\ nil)

    defp value({:list_value, nil}, _, _, default), do: default
    defp value({:list_value, value}, _, _, _), do: value

    defp value(value, _form, _attribute, _) when not is_nil(value), do: value

    defp value(_value, form, attribute, default) do
    value = Phoenix.HTML.FormData.input_value(form.source, form, attribute.name)

    case value do
      nil ->
        case attribute.default do
          nil ->
            default

          func when is_function(func) ->
            default

          attribute_default ->
            attribute_default
        end

      value ->
        value
    end
    end

    def to_name(:id), do: "ID"

    def to_name(name) do
    name
    |> to_string()
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
    end

    def collect_prepare_params(fields) do
    all_prepare_params =
      Enum.reduce(fields, [], fn attribute, acc ->
        # even enum types
        # check whether the module has the needs_prepare_params
        if (Ash.Type.embedded_type?(attribute.type) and attribute.needs_prepare_params) ||
             Keyword.has_key?(attribute.__info__(:functions), :needs_prepare_params) do
          Enum.concat(acc, [attribute.prepare_params])
        else
          acc
        end
      end)

    prepare_params = fn params, extra ->
      Enum.reduce(all_prepare_params, params, fn prepare_params, acc ->
        prepare_params.(acc, extra)
      end)
    end

    prepare_params
    end

    """

    create_module(igniter, module_name, code)
    # |> add_render_to_form_module(module_name)
  end

  defp add_code_to_zipper(zipper, new_code) do
    with {:ok, zipper} <- Igniter.Code.Common.move_to_do_block(zipper) do
      zipper
      |> Igniter.Code.Common.add_code(new_code, :after)
    else
      error ->
        Logger.info("error #{inspect(error)}")
        {:warning, "..."}
    end
  end
end
