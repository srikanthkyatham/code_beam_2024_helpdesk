defmodule Helpdesk.Utils.MethodToParam do
  @moduledoc false

  def to_strings(methods, to_method) when is_list(methods) do
    Enum.map(methods, fn method -> to_method.(method) end)
  end

  def to_strings(_methods, _to_method) do
    []
  end

  def to_methods(params, to_method) when is_list(params) do
    params
    |> Enum.filter(fn param ->
      case param do
        "" -> false
        _ -> true
      end
    end)
    |> Enum.map(fn param ->
      to_method.(param)
    end)
  end

  def to_methods(%Phoenix.HTML.FormField{} = form_field, to_method) do
    to_strings(form_field.value, to_method)
  end
end
