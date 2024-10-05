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
    |> Mix.Tasks.Helpdesk.Generate.PrepareEnumResources.prepare_enum_resources(resources)

    # |> Mix.Tasks.Helpdesk.Generate.FormComponent.add_all_form_modules(resources)
    # |> Mix.Tasks.Helpdesk.Generate.LiveView.add_live_view_files_and_routes(domain, resources)
  end

  defp domain(domain) when is_binary(domain) do
    String.to_existing_atom(domain)
  end

  defp get_resources(domain) when is_atom(domain) do
    Ash.Domain.Info.resource_references(domain) |> Enum.map(fn ref -> ref.resource end)
  end
end
