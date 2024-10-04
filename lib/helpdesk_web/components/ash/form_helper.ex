defmodule HelpdeskWeb.Ash.FormHelper do
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
end
