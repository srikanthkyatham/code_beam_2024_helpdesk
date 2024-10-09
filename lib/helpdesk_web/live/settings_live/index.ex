defmodule HelpdeskWeb.Live.SettingsLive.Index do
  @moduledoc false
  use Phoenix.LiveView

  attr :org_slug, :string, required: true

  def org_links(assigns) do
    ~H"""
    <ul>
      <li><.link navigate={"/auth/#{@org_slug}/tickets"} class="underline">Tickets</.link></li>
      <li>
        <.link navigate={"/auth/#{@org_slug}/representatives"} class="underline">
          Representatives
        </.link>
      </li>
    </ul>
    """
  end

  def render(assigns) do
    ~H"""
    Current temperature: <%= @temperature %>°F <button phx-click="inc_temperature">+</button>
    <ul :for={org_slug <- @org_slugs}>
      <.org_links org_slug={org_slug} />
    </ul>

    <p>Api token</p>
    <p>{@api_token}</p>
    """
  end

  def mount(_params, _session, socket) do
    # get the orgs of the user
    current_user = socket.assigns.current_user |> Ash.load!([:orgs])
    api_token = AshAuthentication.Jwt.token_for_user(current_user)

    org_slugs =
      Enum.map(current_user.orgs, fn org ->
        org.slug
      end)

    temperature = 0
    # orgs from the user ??

    {:ok,
     assign(socket, :temperature, temperature)
     |> assign(:org_slugs, org_slugs)
     |> assign(:api_token, api_token)}
  end

  def handle_event("inc_temperature", _params, socket) do
    {:noreply, update(socket, :temperature, &(&1 + 1))}
  end
end
